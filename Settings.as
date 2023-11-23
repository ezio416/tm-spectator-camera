/*
c 2023-11-22
m 2023-11-22
*/

enum Camera {
    FollowAll,
    FollowSingle,
    ReplaySingle,
    Free,
    None
}

[Setting category="General" name="Enabled"]
bool S_Enabled = true;

[Setting category="General" name="Show window"]
bool S_Window = true;

[Setting category="General" name="Show dev window"]
bool S_Dev = false;

[Setting category="General" name="Default camera"]
Camera S_DefaultCam = Camera::FollowSingle;

[Setting category="General" name="Remember last camera used when joining server"]
bool S_RememberLast = false;