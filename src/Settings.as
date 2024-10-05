// c 2023-11-22
// m 2024-04-02

[Setting category="General" name="Enabled"]
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
