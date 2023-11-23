/*
c 2023-09-06
m 2023-11-22
*/

Camera camChoice = S_DefaultCam;
Camera camCurrent = Camera::None;
string title = "\\$0D0" + Icons::VideoCamera + " \\$GSpectator Camera";

void RenderMenu() {
    if (UI::MenuItem(title, "", S_Enabled))
        S_Enabled = !S_Enabled;
}

void Render() {
    if (!S_Enabled)
        return;

    RenderDev();

    if (!S_Window)
        return;

    CTrackMania@ App = cast<CTrackMania@>(GetApp());

    CSmArenaClient@ Playground = cast<CSmArenaClient@>(App.CurrentPlayground);
    if (Playground is null)
        return;

    CGamePlaygroundInterface@ Interface = cast<CGamePlaygroundInterface@>(Playground.Interface);
    if (Interface is null)
        return;

    CGameScriptHandlerPlaygroundInterface@ Handler = cast<CGameScriptHandlerPlaygroundInterface@>(Interface.ManialinkScriptHandler);
    if (Handler is null)
        return;

    CGamePlaygroundClientScriptAPI@ Api = cast<CGamePlaygroundClientScriptAPI@>(Handler.Playground);
    if (Api is null)
        return;

    CTrackManiaNetwork@ Network = cast<CTrackManiaNetwork@>(App.Network);
    if (Network is null)
        return;

    CGameManiaAppPlayground@ ManiaApp = cast<CGameManiaAppPlayground@>(Network.ClientManiaAppPlayground);
    if (ManiaApp is null)
        return;

    CGamePlaygroundUIConfig@ Client = cast<CGamePlaygroundUIConfig@>(ManiaApp.ClientUI);
    if (Client is null)
        return;

    if (Api.IsSpectatorClient) {
        CGamePlaygroundClientScriptAPI::ESpectatorCameraType camType = Api.GetSpectatorCameraType();
        CGamePlaygroundClientScriptAPI::ESpectatorTargetType targetType = Api.GetSpectatorTargetType();

        if (camType == CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Free)
            camCurrent = Camera::Free;
        else if (camType == CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow) {
            if (targetType == CGamePlaygroundClientScriptAPI::ESpectatorTargetType::Single)
                camCurrent = Camera::FollowSingle;
            else
                camCurrent = Camera::FollowAll;
        } else if (camType == CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Replay) {
            if (targetType == CGamePlaygroundClientScriptAPI::ESpectatorTargetType::Single)
                camCurrent = Camera::ReplaySingle;
            else
                camCurrent = Camera::FollowAll;
        }
    } else
        camCurrent = Camera::None;

    UI::Begin(title, UI::WindowFlags::AlwaysAutoResize);
        UI::Text("Current Camera: " + tostring(camCurrent));
    UI::End();
}