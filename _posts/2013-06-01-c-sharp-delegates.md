---
layout:     post
title:      "C#跨线程修改控件"
subtitle:   "——从MSIL和汇编看事件委托"
date:       2013-06-01 12:00
author:     "wings27"
header-img: "img/tag-windows.jpg"
tags:
    - CSharp
    - Windows
---

## 目录
{:.no_toc}

- toc
{:toc}


#### 跨线程修改控件的问题

相信大家刚开始写winform的时候都遇到过这样的问题，当跨线程修改控件属性时会遇到如下的异常：

> 线程间操作无效: 从不是创建控件"progressBar1"的线程访问它。

这是相应的产生上述异常的示例代码（注意事件响应部分）：

`Director.cs`的内容:

```csharp

// DelegateDemo - Director.cs
// by Wings
// Last Modified : 2013-05-28 11:43

using System.Globalization;
using System.Threading;

namespace DelegateDemo
{
    public delegate void PostEventHandler(string postStatus);

    internal class Director
    {
        private static PostEventHandler _report;

        public event PostEventHandler OnReport
        {
            add { _report += value; }
            remove { _report -= value; }
        }

        public static void Test()
        {
            int counter = 0;
            while (counter++ < 100)
            {
                _report(counter.ToString());
                Thread.Sleep(100);
            }
        }
    }
}
```

`Form1.cs`的内容:

```csharp

  // DelegateDemo - Form1.cs
  // by Wings
  // Last Modified : 2013-05-27 19:54
  
  using System;
  using System.Threading;
  using System.Windows.Forms;
  
  namespace DelegateDemo
  {
      public partial class Form1 : Form
      {
          public Form1()
          {
              InitializeComponent();
          }
  
          private void button1_Click(object sender, EventArgs e)
          {
              Director director = new Director();
              director.OnReport += director_OnReport;
              Thread thread = new Thread(Director.Test)
                              {
                                  Name = "thdDirector"
                              };
              thread.Start();
          }
  
          private void director_OnReport(string postStatus)
          {
              int value = Convert.ToInt32(postStatus);
              this.progressBar1.Value = value;  //此处产生异常
          }
      }
  }
```

我们知道多线程下处于竞态条件（Race Condition[^1]）的资源状态同步可能出现冲突。因此CLR才会禁止这种跨线程修改主窗体控件的行为。

一个简单粗暴（但十分有效）的方法是在主窗体构造函数中加入
`CheckForIllegalCrossThreadCalls = false;`

像这样：

```csharp
public Form1()
{            
    InitializeComponent();
    CheckForIllegalCrossThreadCalls = false;
}
```

附上msdn的解释[^2]：

> CheckForIllegalCrossThreadCalls: 获取或设置一个值，该值指示是否捕获对错误线程的调用，这些调用在调试应用程序时访问控件的 Handle 属性。
因此设为false后将不再检查非法跨线程调用。 

然而毕竟跨线程调用是不安全的，可能导致同步失败。所以我们采用正统一点的方法来解决，那就是调用控件的`Invoke()`或`BeginInvoke()`方法。

二者的差别在于`BeginInvoke()`是异步的，这里为了防止`Director.Test()`执行时主窗体关闭导致句柄失效而产生异常，我们使用`BeginInvoke()`方法进行异步调用。


#### 通过Invoke解决问题

更改过的`Form1.cs`:

```csharp

 // DelegateDemo - Form1.cs
 // by Wings
 // Last Modified : 2013-05-28 13:06
 
 using System;
 using System.Threading;
 using System.Windows.Forms;
 
 namespace DelegateDemo
 {
     public partial class Form1 : Form
     {
         public Form1()
         {
             InitializeComponent();
         }
 
         private void button1_Click(object sender, EventArgs e)
         {
             Director director = new Director();
             director.OnReport += director_OnReport;
             Thread thread = new Thread(Director.Test)
                             {
                                 Name = "thdDirector"
                             };
             thread.Start();
         }
 
         private void director_OnReport(string postStatus)
         {
             int value = Convert.ToInt32(postStatus);
             if (this.progressBar1.InvokeRequired)
             {
                 SetValueCallback setValueCallback = delegate(int i)
                                                     {
                                                         this.progressBar1.Value = i;
                                                     };
                 this.progressBar1.BeginInvoke(setValueCallback, value);
             }
             else
             {
                 this.progressBar1.Value = value;
             }
         }
 
         private delegate void SetValueCallback(int value);
     }
 }
```

至此，问题解决。

然而！！！我们都知道一个不想当Geek的码农不是合格的程序猿~

于是再次发扬Geek精神，尝试剥去.NET粉饰的外衣，窥其真理的内核。


#### 源码分析

先从`Invoke()`入手，看源码：

```csharp
public object Invoke(Delegate method, params object[] args)
{
    using (new Control.MultithreadSafeCallScope())
    return this.FindMarshalingControl().MarshaledInvoke(this, method, args, true);
}
```

而`BeginInvoke()`差别仅仅在于`MarshaledInvoke()`的参数是否`synchronous`:

```csharp
public IAsyncResult BeginInvoke(Delegate method, params object[] args)
{
      using (new Control.MultithreadSafeCallScope())
        return (IAsyncResult) this.FindMarshalingControl().MarshaledInvoke(this, method, args, false);
}
```

实质都是调用了`MarshaledInvoke`方法。

Marshaled这个词常写Native Methods的同学一定很熟悉。对应的中文翻译我。。不知道。。 貌似是叫“编组”。

给出维基百科的释义[^3]作为参考吧：

>In computer science, marshalling (sometimes spelled marshaling with a single l) is the process of transforming the memory representation of an object to a data format suitable for storage or transmission, and it is typically used when data must be moved between different parts of a computer program or from one program to another. Marshalling is similar to serialization and is used to communicate to remote objects with an object, in this case a serialized object. It simplifies complex communication, using custom/complex objects to communicate instead of primitives. The opposite, or reverse, of marshalling is called unmarshalling (or demarshalling, similar to deserialization).

所以.NET的“暗箱操作”很有可能就在`MarshaledInvoke`里面。我们点进去看一下，当然主要关注NativeMethods

```csharp
private object MarshaledInvoke(Control caller, Delegate method, object[] args, bool synchronous)
    {
      if (!this.IsHandleCreated)
        throw new InvalidOperationException(System.Windows.Forms.SR.GetString("ErrorNoMarshalingThread"));
      if ((Control.ActiveXImpl) this.Properties.GetObject(Control.PropActiveXImpl) != null)
        System.Windows.Forms.IntSecurity.UnmanagedCode.Demand();
      bool flag = false;
      int lpdwProcessId;
      if (System.Windows.Forms.SafeNativeMethods.GetWindowThreadProcessId(new HandleRef((object) this, this.Handle), out lpdwProcessId) == System.Windows.Forms.SafeNativeMethods.GetCurrentThreadId() && synchronous)
        flag = true;
      ExecutionContext executionContext = (ExecutionContext) null;
      if (!flag)
        executionContext = ExecutionContext.Capture();
      Control.ThreadMethodEntry threadMethodEntry = new Control.ThreadMethodEntry(caller, this, method, args, synchronous, executionContext);
      lock (this)
      {
        if (this.threadCallbackList == null)
          this.threadCallbackList = new Queue();
      }
      lock (this.threadCallbackList)
      {
        if (Control.threadCallbackMessage == 0)
          Control.threadCallbackMessage = System.Windows.Forms.SafeNativeMethods.RegisterWindowMessage(Application.WindowMessagesVersion + "_ThreadCallbackMessage");
        this.threadCallbackList.Enqueue((object) threadMethodEntry);
      }
      if (flag)
        this.InvokeMarshaledCallbacks();
      else
       // 这里就是纯天然原生态NativeMethod
      System.Windows.Forms.UnsafeNativeMethods.PostMessage(new HandleRef((object) this, this.Handle), Control.threadCallbackMessage, IntPtr.Zero, IntPtr.Zero);
      if (!synchronous)
        return (object) threadMethodEntry;
      if (!threadMethodEntry.IsCompleted)
        this.WaitForWaitHandle(threadMethodEntry.AsyncWaitHandle);
      if (threadMethodEntry.exception != null)
        throw threadMethodEntry.exception;
      else
        return threadMethodEntry.retVal;
}
```

这个`System.Windows.Forms.UnsafeNativeMethods.PostMessage()`就是WinAPI封装过后的NativeMethod了。当然它披上另一件衣服之后也是MFC里面的`CWnd::PostMessage`, 负责向窗体消息队列中放置一条消息，并且不等待消息被处理而直接返回（这里的异步也是与`SendMessage`的主要差别）。

MSDN文档[^4]：
> Places a message in the window's message queue and then returns without waiting for the corresponding window to process the message.

这也就解释了上述情况发生的原因，调用`Invoke()`而不是直接更改控件值使得主窗体能够将消息加入自身的消息队列中，从而在合适的时间处理消息，这样跨线程更改控件值就转变为窗体线程自己更改控件值，也就是从创建控件的线程（窗体主线程）访问控件，避免了之前的错误。


#### InvokeRequired属性探究

还有一个问题，如果本来就是窗体线程对控件进行访问呢，毫无疑问直接设置值即可。在上面的代码中我使用InvokeRequired属性来判断控件更改者是否来自于其他线程，从而决定是调`Invoke()`还是直接改。那么这个属性是否真的如我们所想，仅仅是判断调用者线程呢？看代码：

`InvokeRequired:`

```csharp
[SRDescription("ControlInvokeRequiredDescr")]
[DesignerSerializationVisibility(DesignerSerializationVisibility.Hidden)]
[Browsable(false)]
[EditorBrowsable(EditorBrowsableState.Advanced)]
public bool InvokeRequired
{
      get
      {
        using (new Control.MultithreadSafeCallScope())
        {
          HandleRef hWnd;
          if (this.IsHandleCreated)
          {
            hWnd = new HandleRef((object) this, this.Handle);
          }
          else
          {
            Control marshalingControl = this.FindMarshalingControl();
            if (!marshalingControl.IsHandleCreated)
              return false;
            hWnd = new HandleRef((object) marshalingControl, marshalingControl.Handle);
          }
          int lpdwProcessId;
          return System.Windows.Forms.SafeNativeMethods.GetWindowThreadProcessId(hWnd, out lpdwProcessId) != System.Windows.Forms.SafeNativeMethods.GetCurrentThreadId();
        }
      }
    }
```

果然如此，最后的return写得很清楚。

至此，我们已经理解了Invoke的具体实现。


#### 事件委托的工作原理

下面来看事件委托，为什么`Director.Test()`能够触发`director_OnReport()`回调函数。

我们在`button1_Click()`函数中添加了回调`director.OnReport += director_OnReport;`于是`OnReport`事件执行了`add{_report += value;}`完成添加回调的过程。

基于前面的现象我们知道`progressBar1`是在非窗体线程被更改的（见Invoke实现），既然是来自非窗体线程的更改，那么会不会是本来在窗体类中的`director_OnReport(string postStatus)`函数在回调绑定完成之后直接被替换到了`Director.Test()`中的`_report(counter.ToString());`呢？

从表象上我们有理由怀疑这一点，那么实际验证一下吧。

想了解其底层实现，我们先看看Director类的MSIL吧（话说MSIL现已被微软正名为CIL，微软一匡天下之心昭然若揭。。。）

`Director - MSIL`

```MSIL
.method public hidebysig specialname instance void 
        add_OnReport(class DelegateDemo.PostEventHandler 'value') cil managed
{
  // 代码大小       23 (0x17)
  .maxstack  8
  IL_0000:  nop
  IL_0001:  ldsfld     class DelegateDemo.PostEventHandler DelegateDemo.Director::_report
  IL_0006:  ldarg.1
  IL_0007:  call       class [mscorlib]System.Delegate [mscorlib]System.Delegate::Combine(class [mscorlib]System.Delegate,
                                                                                          class [mscorlib]System.Delegate)
  IL_000c:  castclass  DelegateDemo.PostEventHandler
  IL_0011:  stsfld     class DelegateDemo.PostEventHandler DelegateDemo.Director::_report
  IL_0016:  ret
} // end of method Director::add_OnReport

.event DelegateDemo.PostEventHandler OnReport
{
  .addon instance void DelegateDemo.Director::add_OnReport(class DelegateDemo.PostEventHandler)
  .removeon instance void DelegateDemo.Director::remove_OnReport(class DelegateDemo.PostEventHandler)
} // end of event Director::OnReport
```

`OnReport`事件的内容被编译为两个函数。我们先只看`add_OnReport`这个函数，无非是与Property的Getter和Setter类似，对内绑定到`_report()`函数。那么再来看Form1中对`OnReport`事件的注册：

`button1_Click - MSIL`

```MSIL
.method private hidebysig instance void  button1_Click(object sender,
                                                       class [mscorlib]System.EventArgs e) cil managed
{
  // 代码大小       66 (0x42)
  .maxstack  3
  .locals init ([0] class DelegateDemo.Director director,
           [1] class [mscorlib]System.Threading.Thread thread,
           [2] class [mscorlib]System.Threading.Thread '<>g__initLocal0')
  IL_0000:  nop
  IL_0001:  newobj     instance void DelegateDemo.Director::.ctor()
  IL_0006:  stloc.0
  IL_0007:  ldloc.0
  IL_0008:  ldarg.0
  IL_0009:  ldftn      instance void DelegateDemo.Form1::director_OnReport(string)
  IL_000f:  newobj     instance void DelegateDemo.PostEventHandler::.ctor(object,
                                                                          native int)
  IL_0014:  callvirt   instance void DelegateDemo.Director::add_OnReport(class DelegateDemo.PostEventHandler)
  IL_0019:  nop
  IL_001a:  ldnull
  IL_001b:  ldftn      void DelegateDemo.Director::Test()
  IL_0021:  newobj     instance void [mscorlib]System.Threading.ThreadStart::.ctor(object,
                                                                                   native int)
  IL_0026:  newobj     instance void [mscorlib]System.Threading.Thread::.ctor(class [mscorlib]System.Threading.ThreadStart)
  IL_002b:  stloc.2
  IL_002c:  ldloc.2
  IL_002d:  ldstr      "thdDirector"
  IL_0032:  callvirt   instance void [mscorlib]System.Threading.Thread::set_Name(string)
  IL_0037:  nop
  IL_0038:  ldloc.2
  IL_0039:  stloc.1
  IL_003a:  ldloc.1
  IL_003b:  callvirt   instance void [mscorlib]System.Threading.Thread::Start()
  IL_0040:  nop
  IL_0041:  ret
} // end of method Form1::button1_Click
```

其中`IL_0009:  ldftn`位置到`IL_000f:  newobj`位置声明并实例化了`director_OnReport`作为委托的target，而`IL_0014:  callvirt`位置调用了`add_OnReport()`进行实际意义上的绑定。

然后从`IL_001b:  ldftn`位置开始实例化新线程并进行相关赋值操作，直到`IL_003b:  callvirt`位置调用`Thread::Start()`启动线程。

这样我们已经基本理清了绑定的实现过程，但是代码在执行时是否如上面所说是“函数在回调绑定完成之后直接被替换”这样呢？想要验证就必须再看MSIL的底层实现，就是汇编啦。


#### 事件委托的本质

打开高端大气上档次的反汇编工具，在Director类中设定断点。

这里我们主要看以下两处：

断点0：行26: `add { _report += value; }`

断点1：行35: `_report(counter.ToString(CultureInfo.InvariantCulture));`

开始调试，点击button1，第一次中断在断点0处：

`Director.cs - Asm`内容：（参考注释）

```Assembly
--- Director.cs ----------------
 push        ebp  //各种压栈，为后面还原现场
 mov         ebp,esp 
 push        edi 
 push        esi 
 push        ebx 
 sub         esp,38h 
 xor         eax,eax 
0000000b  mov         dword ptr [ebp-10h],eax 
0000000e  xor         eax,eax 
 mov         dword ptr [ebp-1Ch],eax 
 mov         dword ptr [ebp-3Ch],ecx 
 mov         dword ptr [ebp-40h],edx 
 cmp         dword ptr ds:[00289080h],0 
 je          00000027 
 call        78C0FD41 
//这里开始对应 add { _report += value; }
 nop  //获得数据段地址寄存器偏移量02A184B8h（每次运行不同）处的值，赋给ecx寄存器，这个偏移量下面还会见到。
 mov         ecx,dword ptr ds:[02A184B8h] 
0000002e  mov         edx,dword ptr [ebp-40h] 
 call        77EE1804  //调用Delegate Combine()
 mov         dword ptr [ebp-44h],eax 
 cmp         dword ptr [ebp-44h],0 
0000003d  je          0000005E 
0000003f  mov         eax,dword ptr [ebp-44h] 
 cmp         dword ptr [eax],4430824h 
 jne         0000004F 
0000004a  mov         eax,dword ptr [ebp-44h] 
0000004d  jmp         0000005C  //直接跳到00000061位置
0000004f  mov         edx,dword ptr [ebp-44h] 
 mov         ecx,4430824h 
 call        7899A73E 
0000005c  jmp         00000061 
0000005e  mov         eax,dword ptr [ebp-44h] 
 lea         edx,ds:[02A184B8h] 
 call        789911C8  //未跟踪
0000006c  nop 
0000006d  lea         esp,[ebp-0Ch] 
 pop         ebx 
 pop         esi 
 pop         edi 
 pop         ebp 
 ret  
```

其中Combine的代码我省略了。

运行到断点1：

`Director.cs - Asm`内容：

```Assembly
--- Director.cs ----------------
//对应_report(counter.ToString(CultureInfo.InvariantCulture));
 nop  //这个非常眼熟的偏移地址02A184B8h值又传送至eax寄存器，这个偏移就是数据段中的函数地址
 mov         eax,dword ptr ds:[02A184B8h] 
0000003e  mov         dword ptr [ebp-48h],eax 
 lea         eax,[ebp-3Ch] 
 mov         dword ptr [ebp-4Ch],eax 
 call        77E72110  //这里构造了个CultureInfo
0000004c  mov         dword ptr [ebp-50h],eax 
0000004f  mov         edx,dword ptr [ebp-50h] 
 mov         ecx,dword ptr [ebp-4Ch] 
 call        7838EDA4  //调用NumberFormatInfo(), 还是Culture类相关的，做了些i18n的事情
0000005a  mov         dword ptr [ebp-54h],eax 
0000005d  mov         edx,dword ptr [ebp-54h] 
 mov         ecx,dword ptr [ebp-48h] 
 mov         eax,dword ptr [ecx+0Ch] 
 mov         ecx,dword ptr [ecx+4] 
 call        eax  //此时eax中的值就是ds:[02A184B8h]的值，call后直接来到director_OnReport()，见下。
0000006b  nop
```

直接跳转到了函数`director_OnReport()`

那就再来看`Form1.cs - Asm`

```Assembly
// 从这是跳到函数director_OnReport()
 nop
            //int value = Convert.ToInt32(postStatus);
 mov         ecx,dword ptr [ebp-40h] 
 call        03B4E948 
0000005b  mov         dword ptr [ebp-58h],eax 
0000005e  mov         eax,dword ptr [ebp-58h] 
 mov         dword ptr [ebp-44h],eax 
            //这里是 if (this.progressBar1.InvokeRequired)
 mov         eax,dword ptr [ebp-3Ch] 
 mov         ecx,dword ptr [eax+00000144h] 
0000006d  mov         eax,dword ptr [ecx] 
0000006f  call        dword ptr [eax+00000128h] 
 mov         dword ptr [ebp-5Ch],eax 
 cmp         dword ptr [ebp-5Ch],0 
0000007c  sete        al 
0000007f  movzx       eax,al 
 mov         dword ptr [ebp-50h],eax 
 cmp         dword ptr [ebp-50h],0 
 jne         0000012D 
0000008f  nop 
```

这就充分说明在C#代码层面上执行的`_report()`函数和`director_OnReport()`回调函数本质上是同一个函数（段地址相同），也恰好解释了为什么Form1类中的私有函数为什么可以在其他类调用
。因为C#也好，CIL也好，都是表层的封装，而在CLR中真正运行的，是CLR Assembly.

我们说CLR是虚拟机，这个“虚拟”仅仅指CLR中的指令并非与物理硬件相关联，但是指令集在虚拟机层面与x86 CPU的指令在物理机层面的含义本质上是相同的。
.NET美轮美奂的亭台楼榭都建立在汇编的一砖一瓦之上。而在CLR Assembly层面，只有内核级的概念，这也是我们能够看到其实质的原因。


#### 总结

总结起来C#的窗体事件本质上与MFC的窗体事件一样，都基于Windows API提供的窗体事件消息循环机制实现（主要实现是窗体消息队列）。

为了更新控件又想要避免耗时操作导致卡顿，或者为了跨线程修改窗体控件，我们都可以用.NET提供的Invoke方法（或BeginInvoke）实现。这一方法本质上是通过加入消息至窗体消息循环来实现。

C#事件委托绑定的回调在实现上就是调用同一函数，可以验证其在方法区上的地址相同。

所以在使用.NET封装好的模块和功能模型时，如果能够同时理解其底层实现，相信会对软件开发工作大有裨益。 

以及，要养成写博客的好习惯~

```
// 看自己N年前的博客，有一种莫名的羞耻感。。 ~(@^_^@)~
```


#### 参考文献

[^1]: [Race condition - Wikipedia](http://en.wikipedia.org/wiki/Race_condition)
[^2]: [Control.CheckForIllegalCrossThreadCalls 属性 - MSDN](https://msdn.microsoft.com/zh-cn/library/system.windows.forms.control.checkforillegalcrossthreadcalls%28v=vs.110%29.aspx)
[^3]: [Marshalling - (computer science)](http://en.wikipedia.org/wiki/Marshalling_%28computer_science%29)
[^4]: [CWnd::PostMessage - MSDN](https://msdn.microsoft.com/en-us/library/9tdesxec.aspx)
