/*
c 2023-09-06
m 2023-11-27
*/

Camera     camCurrent      = Camera::None;
string     colorFalse       = "\\$F00false";
string     colorTrue        = "\\$0F0true";
bool       cotd            = false;
string     gamemode;
// bool       inGameAlready   = false;
bool       local           = false;
string     loginLastViewed;
string     loginLocal      = GetLocalLogin();
string     loginDesired;
string     loginViewing;
int        pendingOffset   = 0;
int        playerIndex;
bool       replay          = false;
bool       spectating      = false;
string     title           = "\\$0D0" + Icons::VideoCamera + " \\$GSpec Cam";
uint       totalSpectators = 0;
CSmPlayer@ ViewingPlayer;
bool       watcher         = false;

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

    // if (!S_Window)
    //     return;

    CTrackMania@ App = cast<CTrackMania@>(GetApp());

    if (App.Editor !is null)
        return;

    CSmArenaClient@ Playground = cast<CSmArenaClient@>(App.CurrentPlayground);
    if (Playground is null) {
        // inGameAlready = false;
        loginLastViewed = "";
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

    CTrackManiaNetworkServerInfo@ ServerInfo = cast<CTrackManiaNetworkServerInfo@>(Network.ServerInfo);
    if (ServerInfo is null)
        return;

    gamemode = ServerInfo.CurGameModeStr;
    cotd = gamemode.StartsWith("TM_Knockout");
    local = gamemode.EndsWith("_Local");

    if (Playground.GameTerminals.Length != 1)
        return;

    CSmPlayer@ GUIPlayer = cast<CSmPlayer@>(Playground.GameTerminals[0].GUIPlayer);
    replay = GUIPlayer is null && local;

    @ViewingPlayer = VehicleState::GetViewingPlayer();

    if (ViewingPlayer is null)
        loginViewing = "";
    else {
        loginViewing = ViewingPlayer.ScriptAPI.Login;
        if (loginViewing != loginLocal)
            loginLastViewed = loginViewing;
        else
            loginLastViewed = "";
    }

    spectating = (loginViewing != loginLocal) && !replay;

    if (S_OnlyWhenSpec && !spectating)
        return;

    CGamePlaygroundClientScriptAPI::ESpectatorCameraType camType = Api.GetSpectatorCameraType();
    CGamePlaygroundClientScriptAPI::ESpectatorTargetType targetType = Api.GetSpectatorTargetType();

    switch(camType) {
        case CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Free:
            camCurrent = Camera::Free;
            break;
        case CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow:
            camCurrent = targetType == CGamePlaygroundClientScriptAPI::ESpectatorTargetType::Single ? Camera::FollowSingle : Camera::FollowAll;
            break;
        case CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Replay:
            camCurrent = targetType == CGamePlaygroundClientScriptAPI::ESpectatorTargetType::Single ? Camera::ReplaySingle : Camera::FollowAll;
            break;
        default:
            camCurrent = Camera::None;
    }

    // when switching to a player fails, try the next one
    CGamePlayer@ Player_;
    string login_;
    string name_;
    if (pendingOffset != 0) {
        @Player_ = VehicleState::GetViewingPlayer();
        if (Player_ !is null) {
            if (Player_.User.Login == loginDesired)
                pendingOffset = 0;
            else {
                playerIndex = GetPlayerIndex(Playground.Players.Length, playerIndex, pendingOffset);
                @Player_ = Playground.Players[playerIndex];
                login_ = Player_.User.Login;
                name_ = Player_.User.Name;
                trace("previous switch failed, switching to " + name_);
                if (login_ == loginLocal) {
                    playerIndex = GetPlayerIndex(Playground.Players.Length, playerIndex, pendingOffset);
                    @Player_ = Playground.Players[playerIndex];
                    login_ = Player_.User.Login;
                    name_ = Player_.User.Name;
                    trace("previous switch failed, switching to " + name_);
                }
                Api.SetSpectateTarget(login_);
                loginDesired = login_;
            }
        }
        return;
    }

    if (S_TotalSpec) {
        totalSpectators = 0;
        for (uint i = 0; i < Playground.Players.Length; i++)
            totalSpectators += Playground.Players[i].User.NbSpectators;
    }

    UI::Begin(title, S_Enabled, UI::WindowFlags::AlwaysAutoResize);
        // UI::Text("Spectating: " + (spectating ? "\\$0F0true" : (cotd ? "\\$FF0maybe" : "\\$F00false")));
        // UI::Text("Current Camera: " + tostring(camCurrent));
        // UI::Text("notViewingSelf: " + (notViewingSelf ? boolTrue : boolFalse));
        // UI::Text("nullPlayer: "     + (nullPlayer     ? boolTrue : boolFalse));
        // UI::Text("watcher: "        + (watcher        ? boolTrue : boolFalse));
        UI::Text("Spectating: " + (spectating ? colorTrue : colorFalse));
        // UI::Text("replay: " + replay);
        // UI::Text("lastViewed: " + loginLastViewed);
        if (S_TotalSpec)
            UI::Text("Spectators in game: " + totalSpectators);

        UI::BeginDisabled(cotd || local);
        if (UI::Button("Toggle Spectating " + (Api.IsSpectatorClient ? Icons::ToggleOn : Icons::ToggleOff)))
            Api.RequestSpectatorClient(!Api.IsSpectatorClient);
        UI::EndDisabled();

        UI::Separator();

        UI::BeginDisabled(camCurrent == Camera::ReplaySingle || !spectating);
        if (UI::Button("Replay " + Icons::VideoCamera)) {
            if (loginLastViewed == "") {
                CGamePlayer@ Player = cast<CGamePlayer@>(Playground.Players[0]);
                if (Player.User.Login == loginLocal)
                    @Player = cast<CGamePlayer@>(Playground.Players[1]);
                Api.SetSpectateTarget(Player.User.Login);
            } else
                Api.SetSpectateTarget(loginLastViewed);
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Replay);
            Client.Spectator_SetForcedTarget_Clear();
        }
        UI::EndDisabled();

        UI::SameLine();
        UI::BeginDisabled(camCurrent == Camera::FollowSingle || !spectating);
        if (UI::Button("Follow " + Icons::Eye)) {
            if (loginLastViewed == "") {
                CGamePlayer@ Player = cast<CGamePlayer@>(Playground.Players[0]);
                if (Player.User.Login == loginLocal)
                    @Player = cast<CGamePlayer@>(Playground.Players[1]);
                Api.SetSpectateTarget(Player.User.Login);
            } else
                Api.SetSpectateTarget(loginLastViewed);

            // Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Replay);
            // Client.Spectator_SetForcedTarget_Clear();
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

        if (spectating && (camCurrent == Camera::FollowSingle || camCurrent == Camera::ReplaySingle)) {
            UI::Separator();

            string login;
            string name;

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

            bool clicked = false;
            int offset = 0;
            CGamePlayer@ Player;

            UI::BeginDisabled(playerIndex == -1 || pendingOffset != 0);
            if (UI::Button(Icons::ChevronLeft + " Previous")) {
                clicked = true;
                offset = -1;
            }

            UI::SameLine();
            if (UI::Button("Next " + Icons::ChevronRight)) {
                clicked = true;
                offset = 1;
            }

            if (clicked) {
                playerIndex = GetPlayerIndex(Playground.Players.Length, playerIndex, offset);
                @Player = Playground.Players[playerIndex];
                login = Player.User.Login;
                name = Player.User.Name;
                trace("switching to " + name);
                if (login == loginLocal) {
                    playerIndex = GetPlayerIndex(Playground.Players.Length, playerIndex, offset);
                    @Player = Playground.Players[playerIndex];
                    login = Player.User.Login;
                    name = Player.User.Name;
                    trace("previous switch failed, switching to " + name);
                }
                Api.SetSpectateTarget(login);
                loginDesired = login;
                pendingOffset = offset;
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

uint GetPlayerIndex(uint playerCount, uint currentIndex, int offset) {
    switch (offset) {
        case -1:
            return (currentIndex > 0 ? currentIndex : playerCount) - 1;
        case 1:
            return (currentIndex < playerCount - 1 ? currentIndex + 1 : 0);
        default:
            return currentIndex;
    }
}

// bool IsWatcher() {
//     CTrackMania@ App = cast<CTrackMania@>(GetApp());

//     CTrackManiaNetwork@ Network = cast<CTrackManiaNetwork@>(App.Network);
//     if (Network is null)
//         return false;

//     CTrackManiaPlayerInfo@ PlayerInfo = cast<CTrackManiaPlayerInfo@>(Network.PlayerInfo);
//     if (PlayerInfo is null)
//         return false;

//     return tostring(PlayerInfo.SpectatorMode) == "Watcher";
// }

// bool SpectatorUILayerVisible() {
//     CGameUILayer@ SpecLayer;
//     bool found = false;

//     CTrackMania@ App = cast<CTrackMania@>(GetApp());

//     CSmArenaClient@ Playground = cast<CSmArenaClient@>(App.CurrentPlayground);
//     if (Playground is null)
//         return false;

//     CTrackManiaNetwork@ Network = cast<CTrackManiaNetwork@>(App.Network);
//     if (Network is null)
//         return false;

//     CGameManiaAppPlayground@ ManiaApp = cast<CGameManiaAppPlayground@>(Network.ClientManiaAppPlayground);
//     if (ManiaApp is null)
//         return false;

//     MwFastBuffer<CGameUILayer@> UILayers = ManiaApp.UILayers;

//     for (uint i = 0; i < UILayers.Length; i++) {
//         string manialink = UILayers[i].ManialinkPage;
//         string[]@ firstLines = manialink.Split("\n", 5);

//         if (firstLines.Length > 0) {
//             for (uint j = 0; j < firstLines.Length - 1; j++) {
//                 if (firstLines[j].Contains("UIModule_Race_SpectatorBase")) {
//                     // print("found layer");
//                     @SpecLayer = UILayers[i];
//                     found = true;
//                     break;
//                 }
//             }
//         }

//         if (found)
//             break;
//     }

//     return SpecLayer.IsVisible;
// }