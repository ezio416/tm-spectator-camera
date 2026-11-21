enum Camera {
    FollowAll,
    FollowSingle,
    ReplaySingle,
    Free,
    None
}

[Setting category="General" name="Show window"]
bool S_Enabled = true;

[Setting category="General" name="Only show when spectating"]
bool S_OnlyWhenSpec = true;

#if SIG_DEVELOPER

[Setting category="General" name="Show dev window"]
bool S_Dev = false;

#endif

[Setting category="General" name="Show number of spectators" description="does not work in COTD"]
bool S_TotalSpec = false;

// [Setting category="General" name="Default camera"]
// Camera S_DefaultCam = Camera::FollowSingle;

// [Setting category="General" name="Remember last camera used when joining server"]
// bool S_RememberLast = false;

// [Setting hidden]
// Camera camLast = Camera::None;


enum Hotkey {
    None = -1,
    Replay,
    Follow,
    FollowAll,
    Free,
}


[Setting category="Hotkeys" name="Allow when window is hidden"]
bool S_HiddenHotkeys = false;

[Setting category="Hotkeys" name="Replay camera"]
VirtualKey S_HotkeyReplay = VirtualKey::None;

[Setting category="Hotkeys" name="Follow camera"]
VirtualKey S_HotkeyFollow = VirtualKey::None;

[Setting category="Hotkeys" name="Follow All camera"]
VirtualKey S_HotkeyFollowAll = VirtualKey::None;

[Setting category="Hotkeys" name="Free camera"]
VirtualKey S_HotkeyFree = VirtualKey::None;
