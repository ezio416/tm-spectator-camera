/*
c 2023-09-06
m 2023-11-23
*/

Camera     camCurrent      = Camera::None;
bool       cotd            = false;
string     gamemode        = "none";
// bool       inGameAlready   = false;
string     loginLastViewed;
string     loginLocal      = GetLocalLogin();
string     loginViewing;
int        playerIndex;
bool       spectating      = false;
string     title           = "\\$0D0" + Icons::VideoCamera + " \\$GSpec Cam";
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

    if (App.Editor !is null)
        return;

    CSmArenaClient@ Playground = cast<CSmArenaClient@>(App.CurrentPlayground);
    if (Playground is null) {
        // inGameAlready = false;
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

    // if (!inGameAlready) {
    //     switch (S_RememberLast ? camLast : S_DefaultCam) {
    //         case Camera::FollowAll:
    //             Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
    //             Client.Spectator_SetForcedTarget_AllPlayers();
    //             break;
    //         case Camera::FollowSingle:
    //             Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
    //             if (loginLastViewed == "none") {
    //                 CGamePlayer@ Player = cast<CGamePlayer@>(Playground.Players[0]);
    //                 if (Player.User.Login == loginLocal)
    //                     @Player = cast<CGamePlayer@>(Playground.Players[1]);
    //                 Api.SetSpectateTarget(Player.User.Login);
    //             }
    //             Client.Spectator_SetForcedTarget_Clear();
    //             break;
    //         case Camera::ReplaySingle:
    //             Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Replay);
    //             if (loginLastViewed == "none") {
    //                 CGamePlayer@ Player = cast<CGamePlayer@>(Playground.Players[0]);
    //                 if (Player.User.Login == loginLocal)
    //                     @Player = cast<CGamePlayer@>(Playground.Players[1]);
    //                 Api.SetSpectateTarget(Player.User.Login);
    //             }
    //             Client.Spectator_SetForcedTarget_Clear();
    //             break;
    //         case Camera::Free:
    //             Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Free);
    //     }
    //     inGameAlready = true;
    // }

    gamemode = cast<CTrackManiaNetworkServerInfo@>(Network.ServerInfo).CurGameModeStr;
    cotd = gamemode.StartsWith("TM_Knockout");

    @ViewingPlayer = VehicleState::GetViewingPlayer();
    if (ViewingPlayer !is null) {
        loginViewing = ViewingPlayer.ScriptAPI.Login;
        loginLastViewed = loginViewing;
        spectating = (loginViewing != loginLocal);
    } else {
        loginViewing = "none";
        spectating = Api.IsSpectatorClient;
    }

    if (S_OnlyWhenSpec && !spectating && !cotd)
        return;

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
    } else if (camType == CGamePlaygroundClientScriptAPI::ESpectatorTargetType::None)
        camCurrent = Camera::None;

    // if (camCurrent != Camera::None)
    //     camLast = camCurrent;

    UI::Begin(title, S_Window, UI::WindowFlags::AlwaysAutoResize);
        UI::Text("Spectating: " + (spectating ? "\\$0F0true" : (cotd ? "\\$FF0maybe" : "\\$F00false")));
        // UI::Text("Current Camera: " + tostring(camCurrent));

        if (UI::Button("Toggle Spectating " + (Api.IsSpectatorClient ? Icons::ToggleOn : Icons::ToggleOff)))
            Api.RequestSpectatorClient(!Api.IsSpectatorClient);

        UI::Separator();

        UI::BeginDisabled(camCurrent == Camera::ReplaySingle || (!spectating && !cotd));
        if (UI::Button("Replay " + Icons::VideoCamera)) {
            if (loginLastViewed == "none") {
                CGamePlayer@ Player = cast<CGamePlayer@>(Playground.Players[0]);
                if (Player.User.Login == loginLocal)
                    @Player = cast<CGamePlayer@>(Playground.Players[1]);
                Api.SetSpectateTarget(Player.User.Login);
            }
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Replay);
            Client.Spectator_SetForcedTarget_Clear();
        }
        UI::EndDisabled();

        UI::SameLine();
        UI::BeginDisabled(camCurrent == Camera::FollowSingle || (!spectating && !cotd));
        if (UI::Button("Follow " + Icons::Eye)) {
            if (loginLastViewed == "none") {
                CGamePlayer@ Player = cast<CGamePlayer@>(Playground.Players[0]);
                if (Player.User.Login == loginLocal)
                    @Player = cast<CGamePlayer@>(Playground.Players[1]);
                Api.SetSpectateTarget(Player.User.Login);
            } else
                Api.SetSpectateTarget(loginLastViewed);

            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
            Client.Spectator_SetForcedTarget_Clear();
        }
        UI::EndDisabled();

        UI::BeginDisabled(camCurrent == Camera::FollowAll || (!spectating && !cotd));
        if (UI::Button("Follow All " + Icons::Kenney::Checkbox)) {
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
            Client.Spectator_SetForcedTarget_AllPlayers();
        }
        UI::EndDisabled();

        UI::SameLine();
        UI::BeginDisabled(camCurrent == Camera::Free || (!spectating && !cotd));
        if (UI::Button("Free " + Icons::VideoCamera))
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Free);
        UI::EndDisabled();

        if ((spectating || cotd) && (camCurrent == Camera::FollowSingle || camCurrent == Camera::ReplaySingle)) {
            UI::Separator();

            string login;

            if (ViewingPlayer !is null)
                UI::Text("Watching: " + ViewingPlayer.User.Name);

            playerIndex = -1;
            for (uint i = 0; i < Playground.Players.Length; i++) {
                login = Playground.Players[i].User.Login;
                if (login == loginViewing) {
                    playerIndex = i;
                    break;
                }
                if (login == loginLocal)
                    playerIndex = -1;
            }

            UI::BeginDisabled(playerIndex == -1);
            if (UI::Button(Icons::ChevronLeft + " Previous")) {
                login = Playground.Players[(uint(playerIndex) == 0 ? Playground.Players.Length : playerIndex) - 1].User.Login;
                if (login == loginLocal) {
                    playerIndex -= 1;
                    login = Playground.Players[(uint(playerIndex) == 0 ? Playground.Players.Length : playerIndex) - 1].User.Login;
                }
                Api.SetSpectateTarget(login);
            }
            UI::SameLine();
            if (UI::Button("Next " + Icons::ChevronRight)) {
                login = Playground.Players[(uint(playerIndex) == Playground.Players.Length - 1 ? -1 : playerIndex) + 1].User.Login;
                if (login == loginLocal) {
                    playerIndex += 1;
                    login = Playground.Players[(uint(playerIndex) == Playground.Players.Length - 1 ? -1 : playerIndex) + 1].User.Login;
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