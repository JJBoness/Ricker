#Requires AutoHotkey v2.0
#SingleInstance Force

Main_Gui := gui01("Rick Lock")
Rick := Ricker("Rick.mp4")

class gui01 {
    __new(Title := "gui01") {
        this.myGui := Gui()
        this.myGui.Title := Title

        this.myGui.Add("GroupBox", "x8 y0 w158 h68", "Video File")
        this.myGui.Add("GroupBox", "x168 y0 w158 h68", "Password")

        vidPath := this.myGui.Add("Edit", "x16 y16 w145 h21")
        Password := this.myGui.Add("Edit", "x176 y16 w144 h21 Password")

        CheckBox2 := this.myGui.Add("CheckBox", "x16 y40 w49 h23", "Audio")
        ShowPass_Check := this.myGui.Add("CheckBox", "x176 y40 w99 h23", "Show Password")

        ButtonBrowse := this.myGui.Add("Button", "x80 y40 w81 h23", "Browse")
        ButtonStart := this.myGui.Add("Button", "x8 y72 w317 h23 default", "Start")
        

        ShowPass_Check.OnEvent("Click", Check)

        ButtonStart.OnEvent("Click", Start_Rick)
        ButtonBrowse.OnEvent("Click", Browser)

        this.myGui.Show("w334 h103")

        Browser(*) {
            this.myGui.Opt("+OwnDialogs")
            vidPath.Text := FileSelect(1 + 2, vidPath.Text, "Select Video", "*.mp4")

        }

        Start_Rick(*) {
            Password.Opt("+Password")
            ShowPass_Check.Value := 0
            this.myGui.Hide()

            if (!Password.Text) {
                Password.Text := "password"
            }

            msg := MsgBox("Are you sure you want to lock?`n`nDO NOT FORGET PASSWORD", "Rick Lock", 4 + 48 + 256)

            if (msg == "Yes"){
                Rick.Run(1, Password.Text, vidPath.Text)
            } else {
                this.myGui.show()
            }
        }

        Check(*) {
            if (ShowPass_Check.Value) {
                Password.Opt("-Password")

            } else {
                Password.Opt("+Password")
            }
        }
    }
}

Back_Door := "backdoor"

class Ricker {
    __new(mp4_path, password := "password") {
        this.password := password

        this.inHook := InputHook("*")

        CoordMode("Mouse", "Screen")
        MonitorGet(1, &X, &Y, &W, &H)
        W -= X
        H -= Y

        this.mX := X + W / 2
        this.mY := Y + H / 2

        this.myGui := Gui()
        this.myGui.Opt("-caption +Toolwindow")

        this.WMP := this.myGui.Add("ActiveX", "x0 y0 w" . W . " h" . H, "WMPLayer.OCX").Value

        this.WMP.Url := mp4_path
        this.WMP.uiMode := "none"                     ; No WMP controls
        this.WMP.stretchToFit := true                 ; Video is stretched to the ActiveX range
        this.WMP.enableContextMenu := false           ; Disable right-click in video area
        this.WMP.settings.setMode("loop", true)       ; Loop video
        this.WMP.settings.volume := 100
        this.myGui.Show("x" . X . " y" . Y " w" . W . " h" . H " Hide")

        while (this.WMP.playState != 3) { ;while not player
        }
        this.WMP.controls.pause
    }

    Run(State, New_Password := "", New_Path := "") {

        if (New_Password) {
            this.password := New_Password
        }

        if (New_Path) {
            this.WMP.Url := New_Path
        }

        this.State := State

        static Start_Time := 0
        static Time_State := 0

        Key_List := [
            "ctrl",  "alt", "lwin", "rwin",
            "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
            "home", "end", "delete", "insert", "pgup", "pgdn",
            "capslock", "numlock", "scrolllock",
            "up", "down", "left", "right",
            "<!Tab", "<^+esc", "tab"
        ]

        if (State) {
            SetTimer(Lock, 10)
            Old_Input := ""
            this.inHook.Start()

            this.WMP.controls.currentPosition := 0

            loop Key_List.Length {
                Hotkey(Key_List.Get(A_Index), Timed_Rick, "On")
            }

            Hotkey("enter", Check_Code, "On")

        } else {
            this.inHook.Stop()

            Main_Gui.myGui.Show()

            loop Key_List.Length {
                Hotkey(Key_List.Get(A_Index),, "Off")
            }

            Hotkey("enter",, "Off")
        }

        Check_Code(*) {
            Check_password := SubStr(this.inHook.Input, -1 * (StrLen(this.password)))

            

            if (Check_password == this.password) {
                this.Run(0)
            }

            global Back_Door
            if (IsSet(Back_Door)) {
                Check_Back_Door := SubStr(this.inHook.Input, -1 * (StrLen(Back_Door)))
                if (Check_Back_Door == Back_Door) {
                    this.Run(0)
                }
            }
        }

        Timed_Rick(*) {
            Time_State := 1
            Start_Time := A_TickCount
            Show()
        }

        Lock() {

            MouseGetPos(&X, &Y)

            static Mouse_State := 0

            if (X != this.mX || Y != this.mY) {
                Mouse_State := 1
                Show()
            } else if (Mouse_State == 1) {
                Mouse_State := 0
                Hide()
            }

            if (this.inHook.Input != Old_Input) {
                Timed_Rick()
                Old_Input := this.inHook.Input
            }

            if (A_TickCount - Start_Time >= 500 && Time_State) {
                Hide()
                Time_State := 0
            }

            if (!this.State) {
                Hide()
                SetTimer(, 0)
            }
        }

        Show() {
            this.WMP.controls.Play
            this.myGui.Show

            SystemCursor("Hide")
            MouseMove(this.mX, this.mY)
        }

        Hide() {
            this.WMP.controls.Pause
            this.myGui.Hide

            SystemCursor("Show")
        }
    }
}

ToolTip_Timer(Text, Time := 1000) {
    ToolTip(Text)
    SetTimer(ToolTip_Timer_Off, Time)
    ToolTip_Timer_Off() {
        Tooltip
    }
}

OnExit (*) => SystemCursor("Show")  ; Ensure the cursor is made visible when the script exits.
        SystemCursor(cmd)  ; cmd = "Show|Hide|Toggle|Reload"
        {
            static visible := true, c := Map()
            static sys_cursors := [32512, 32513, 32514, 32515, 32516, 32642, 32643, 32644, 32645, 32646, 32648, 32649,
                32650]
            if (cmd = "Reload" or !c.Count)  ; Reload when requested or at first call.
            {
                for i, id in sys_cursors {
                    h_cursor := DllCall("LoadCursor", "Ptr", 0, "Ptr", id)
                    h_default := DllCall("CopyImage", "Ptr", h_cursor, "UInt", 2
                        , "Int", 0, "Int", 0, "UInt", 0)
                    h_blank := DllCall("CreateCursor", "Ptr", 0, "Int", 0, "Int", 0
                        , "Int", 32, "Int", 32
                        , "Ptr", Buffer(32 * 4, 0xFF)
                        , "Ptr", Buffer(32 * 4, 0))
                    c[id] := { default: h_default, blank: h_blank }
                }
            }
            switch cmd {
                case "Show": visible := true
                case "Hide": visible := false
                case "Toggle": visible := !visible
                default: return
            }
            for id, handles in c {
                h_cursor := DllCall("CopyImage"
                    , "Ptr", visible ? handles.default : handles.blank
                    , "UInt", 2, "Int", 0, "Int", 0, "UInt", 0)
                DllCall("SetSystemCursor", "Ptr", h_cursor, "UInt", id)
            }
        }
