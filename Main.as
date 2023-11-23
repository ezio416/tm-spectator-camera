/*
c 2023-09-06
m 2023-11-23
*/

Camera camChoice = S_DefaultCam;
Camera camCurrent = Camera::None;
string loginLastViewed;
string loginLocal = GetLocalLogin();
string loginViewing;
bool spectating = false;
string title = "\\$0D0" + Icons::VideoCamera + " \\$GSpectator Camera";
CSmPlayer@ ViewingPlayer;

void Main() {
    startnew(CacheLocalLogin);
}

void RenderMenu() {
    if (UI::MenuItem(title, "", S_Enabled))
        S_Enabled = !S_Enabled;
}

void Render() {
    if (!S_Enabled)
        return;

#if SIG_DEVELOPER
    RenderDev();
#endif

    if (!S_Window)
        return;

    CTrackMania@ App = cast<CTrackMania@>(GetApp());

    CSmArenaClient@ Playground = cast<CSmArenaClient@>(App.CurrentPlayground);
    if (Playground is null) {
        loginLastViewed = "none";
        return;
    }

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

    @ViewingPlayer = VehicleState::GetViewingPlayer();
    if (ViewingPlayer !is null) {
        loginViewing = ViewingPlayer.ScriptAPI.Login;
        loginLastViewed = loginViewing;
        spectating = (loginViewing != loginLocal);
    } else {
        loginViewing = "none";
        spectating = Api.IsSpectatorClient;
    }

    if (spectating) {
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
        UI::Text("Spectating: " + (spectating ? "\\$0F0true" : "\\$F00false"));
        // UI::Text("Current Camera: " + tostring(camCurrent));

        UI::BeginDisabled(camCurrent == Camera::ReplaySingle || !spectating);
        if (UI::Button("Replay " + Icons::VideoCamera)) {
            if (loginLastViewed == "none") {
                CGamePlayer@ Player = cast<CGamePlayer@>(Playground.Players[0]);
                string login = Player.User.Login;
                if (login == loginLocal)  // check if first player is ourself
                    @Player = cast<CGamePlayer@>(Playground.Players[1]);
                Api.SetSpectateTarget(login);
            }
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Replay);
            Client.Spectator_SetForcedTarget_Clear();
        }
        UI::EndDisabled();

        UI::SameLine();
        UI::BeginDisabled(camCurrent == Camera::FollowSingle || !spectating);
        if (UI::Button("Follow " + Icons::Eye)) {
            if (loginLastViewed == "none") {
                CGamePlayer@ Player = cast<CGamePlayer@>(Playground.Players[0]);
                string login = Player.User.Login;
                if (login == loginLocal)  // check if first player is ourself
                    @Player = cast<CGamePlayer@>(Playground.Players[1]);
                Api.SetSpectateTarget(login);
            } else {
                Api.SetSpectateTarget(loginLastViewed);
            }
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
            Client.Spectator_SetForcedTarget_Clear();
        }
        UI::EndDisabled();

        UI::BeginDisabled(camCurrent == Camera::FollowAll || !spectating);
        if (UI::Button("Follow All " + Icons::Kenney::Checkbox)) {
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
            Client.Spectator_SetForcedTarget_AllPlayers();
        }
        UI::EndDisabled();

        UI::SameLine();
        UI::BeginDisabled(camCurrent == Camera::Free || !spectating);
        if (UI::Button("Free " + Icons::VideoCamera))
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Free);
        UI::EndDisabled();

        if (camCurrent == Camera::FollowSingle || camCurrent == Camera::ReplaySingle) {
            if (ViewingPlayer !is null)
                UI::Text("Watching: " + ViewingPlayer.User.Name);
            int index = -1;
            for (uint i = 0; i < Playground.Players.Length; i++) {
                if (Playground.Players[i].User.Login == loginViewing)
                    index = i;
            }
            string login;
            UI::BeginDisabled(index == -1);
            if (UI::Button(Icons::ChevronLeft + " Previous")) {
                login = Playground.Players[(uint(index) == 0 ? Playground.Players.Length : index) - 1].User.Login;
                if (login == loginLocal) {
                    index -= 1;
                    login = Playground.Players[(uint(index) == 0 ? Playground.Players.Length : index) - 1].User.Login;
                }
                Api.SetSpectateTarget(login);
            }
            UI::SameLine();
            if (UI::Button("Next " + Icons::ChevronRight)) {
                login = Playground.Players[(uint(index) == Playground.Players.Length - 1 ? -1 : index) + 1].User.Login;
                if (login == loginLocal) {
                    index += 1;
                    login = Playground.Players[(uint(index) == 0 ? Playground.Players.Length : index) + 1].User.Login;
                }
                Api.SetSpectateTarget(login);
            }
            UI::EndDisabled();
        }
    UI::End();
}

// from "Auto-hide Opponents" plugin - https://github.com/XertroV/tm-autohide-opponents
void CacheLocalLogin() {
    while (true) {
        sleep(100);
        loginLocal = GetLocalLogin();
        if (loginLocal.Length > 10)
            break;
    }
}