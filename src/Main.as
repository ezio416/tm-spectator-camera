// c 2023-09-06
// m 2024-04-02

CameraType camCurrent      = CameraType::None;
string     colorFalse      = "\\$F00false";
string     colorTrue       = "\\$0F0true";
string     loginDesired;
string     loginLastViewed;
string     loginLocal;
int        pendingOffset   = 0;
int        playerIndex;
bool       replay          = false;
string     title           = "\\$0D0" + Icons::VideoCamera + " \\$GSpec Cam";
uint       totalSpectators = 0;
bool       watcher         = false;

void Main() {
    startnew(CacheLocalLogin);

    while (true) {
        yield();
        ForceCamFollowSingle();
    }
}

class CoroRef {
    CGamePlaygroundClientScriptAPI@ Api;
    CGamePlaygroundUIConfig@        Client;

    CoroRef(CGamePlaygroundClientScriptAPI@ api, CGamePlaygroundUIConfig@ client) {
        @Api    = api;
        @Client = client;
    }
}

void ForceCamFollowSingle() {
    CTrackMania@ App = cast<CTrackMania@>(GetApp());
    CTrackManiaNetwork@ Network = cast<CTrackManiaNetwork@>(App.Network);

    if (App.Editor !is null)
        return;

    CSmArenaClient@ Playground = cast<CSmArenaClient@>(App.CurrentPlayground);
    if (Playground is null) {
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

    CGameManiaAppPlayground@ CMAP = Network.ClientManiaAppPlayground;
    if (CMAP is null)
        return;

    CGamePlaygroundUIConfig@ Client = cast<CGamePlaygroundUIConfig@>(CMAP.ClientUI);
    if (Client is null)
        return;

    if (Api.GetSpectatorTargetType() != CGamePlaygroundClientScriptAPI::ESpectatorTargetType::Single) {
        Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Replay);
        Client.Spectator_SetForcedTarget_Clear();

        yield();
    }

    if (Api.GetSpectatorCameraType() == CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Replay)
        Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
}

void RenderMenu() {
    if (UI::MenuItem(title, "", S_Enabled))
        S_Enabled = !S_Enabled;
}

void Render() {
    if (!S_Enabled)
        return;

    CTrackMania@ App = cast<CTrackMania@>(GetApp());

    if (App.Editor !is null)
        return;

    CTrackManiaNetwork@ Network = cast<CTrackManiaNetwork@>(App.Network);

    CGameManiaAppPlayground@ CMAP = Network.ClientManiaAppPlayground;
    if (CMAP is null || CMAP.ClientUI is null)
        return;

    CTrackManiaNetworkServerInfo@ ServerInfo = cast<CTrackManiaNetworkServerInfo@>(Network.ServerInfo);
    const string gamemode = ServerInfo.CurGameModeStr;
    if (gamemode.EndsWith("_Local"))
        return;
    const bool cup = gamemode.StartsWith("TM_Knockout");

    CSmArenaClient@ Playground = cast<CSmArenaClient@>(App.CurrentPlayground);
    if (
        Playground is null
        || Playground.UIConfigs.Length == 0
        || Playground.UIConfigs[0] is null
        || Playground.UIConfigs[0].UISequence != CGamePlaygroundUIConfig::EUISequence::Playing
    ) {
        loginLastViewed = "";
        return;
    }

    CSmArenaInterfaceUI@ Interface = cast<CSmArenaInterfaceUI@>(Playground.Interface);
    if (Interface is null)
        return;

    CSmArenaInterfaceManialinkScripHandler@ Handler = cast<CSmArenaInterfaceManialinkScripHandler@>(Interface.ManialinkScriptHandler);
    if (Handler is null || Handler.Playground is null)
        return;

    CGamePlaygroundClientScriptAPI@ Api = Handler.Playground;

    string loginViewing;

    CSmPlayer@ ViewingPlayer = VehicleState::GetViewingPlayer();
    if (ViewingPlayer !is null) {
        loginViewing = ViewingPlayer.ScriptAPI.Login;
        loginLastViewed = loginViewing != loginLocal ? loginViewing : "";
    }

    const bool spectating = loginViewing != loginLocal;

    if (S_OnlyWhenSpec && !spectating)
        return;

    const bool single = Api.GetSpectatorTargetType() == CGamePlaygroundClientScriptAPI::ESpectatorTargetType::Single;

    switch (Api.GetSpectatorCameraType()) {
        case CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Free:
            camCurrent = CameraType::Free;
            break;
        case CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow:
            camCurrent = single ? CameraType::FollowSingle : CameraType::FollowAll;
            break;
        case CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Replay:
            camCurrent = single ? CameraType::Replay : CameraType::FollowAll;
            break;
        default:
            camCurrent = CameraType::None;
    }

    // when switching to a player fails, try the next one
    //https://github.com/ezio416/tm-spectator-camera/issues/2
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
        } else
            pendingOffset = 0;

        return;
    }

    // https://github.com/ezio416/tm-spectator-camera/issues/5
    if (S_TotalSpec) {
        totalSpectators = 0;
        for (uint i = 0; i < Playground.Players.Length; i++)
            totalSpectators += Playground.Players[i].User.NbSpectators;
    }

    UI::Begin(title, S_Enabled, UI::WindowFlags::AlwaysAutoResize);
        if (!S_OnlyWhenSpec)
            UI::Text("Spectating: " + (spectating ? colorTrue : colorFalse));
        if (S_TotalSpec && !cup)
            UI::Text("Spectators in game: " + totalSpectators);

        UI::BeginDisabled(cup);
        if (UI::Button("Toggle Spectating " + (Api.IsSpectatorClient ? Icons::ToggleOn : Icons::ToggleOff)))
            Api.RequestSpectatorClient(!Api.IsSpectatorClient);
        UI::EndDisabled();

        UI::Separator();

        UI::BeginDisabled(camCurrent == CameraType::Replay || !spectating);
        if (UI::Button("Replay " + Icons::VideoCamera)) {
            if (loginLastViewed == "") {
                CGamePlayer@ Player = Playground.Players[0];
                if (Player.User.Login == loginLocal)
                    @Player = cast<CGamePlayer@>(Playground.Players[1]);
                Api.SetSpectateTarget(Player.User.Login);
            } else
                Api.SetSpectateTarget(loginLastViewed);

            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Replay);
            CMAP.ClientUI.Spectator_SetForcedTarget_Clear();
        }
        UI::EndDisabled();

        UI::SameLine();
        UI::BeginDisabled(camCurrent == CameraType::FollowSingle || !spectating);
        if (UI::Button("Follow " + Icons::Eye)) {
            if (loginLastViewed == "") {
                CGamePlayer@ Player = cast<CGamePlayer@>(Playground.Players[0]);
                if (Player.User.Login == loginLocal)
                    @Player = cast<CGamePlayer@>(Playground.Players[1]);
                Api.SetSpectateTarget(Player.User.Login);
            } else
                Api.SetSpectateTarget(loginLastViewed);

            // https://github.com/ezio416/tm-spectator-camera/issues/3
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
            CMAP.ClientUI.Spectator_SetForcedTarget_Clear();
        }
        UI::EndDisabled();

        UI::BeginDisabled(camCurrent == CameraType::FollowAll || !spectating);
        if (UI::Button("Follow All " + Icons::Kenney::Checkbox)) {
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
            CMAP.ClientUI.Spectator_SetForcedTarget_AllPlayers();
        }
        UI::EndDisabled();

        UI::SameLine();
        UI::BeginDisabled(camCurrent == CameraType::Free || !spectating);
        if (UI::Button("Free " + Icons::VideoCamera))
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Free);
        UI::EndDisabled();

        if (spectating && (camCurrent == CameraType::FollowSingle || camCurrent == CameraType::Replay)) {
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
