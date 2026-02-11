Camera camCurrent      = Camera::None;
string loginLastViewed;
string loginLocal      = GetLocalLogin();
string loginDesired;
string loginViewing;
int    pendingOffset   = 0;
int    playerIndex;
bool   replay          = false;
bool   spectating      = false;
string title           = "\\$0D0" + Icons::VideoCamera + " \\$GSpec Cam";
uint   totalSpectators = 0;

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

    auto App = cast<CTrackMania>(GetApp());
    auto Playground = cast<CSmArenaClient>(App.CurrentPlayground);
    auto Network = cast<CTrackManiaNetwork>(App.Network);
    auto ServerInfo = cast<CTrackManiaNetworkServerInfo>(Network.ServerInfo);

    if (false
        or App.Editor !is null
        or Playground is null
        or Playground.UIConfigs.Length == 0
        or Playground.UIConfigs[0].UISequence != CGamePlaygroundUIConfig::EUISequence::Playing
        or Playground.Interface is null
        or Playground.Interface.ManialinkScriptHandler is null
        or Playground.Interface.ManialinkScriptHandler.Playground is null
        or Network.ClientManiaAppPlayground is null
        or Network.ClientManiaAppPlayground.ClientUI is null
        or Playground.GameTerminals.Length != 1
    ) {
        loginLastViewed = "";
        return;
    }

    CGamePlaygroundClientScriptAPI@ Api = Playground.Interface.ManialinkScriptHandler.Playground;
    CGameManiaAppPlayground@ CMAP = Network.ClientManiaAppPlayground;
    CGamePlaygroundUIConfig@ Client = CMAP.ClientUI;

    const bool cotd = ServerInfo.CurGameModeStr.StartsWith("TM_Knockout");
    const bool local = App.PlaygroundScript !is null;

    auto GUIPlayer = cast<CSmPlayer>(Playground.GameTerminals[0].GUIPlayer);
    replay = GUIPlayer is null && local;

    CSmPlayer@ ViewingPlayer = VehicleState::GetViewingPlayer();

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

    const bool single = Api.GetSpectatorTargetType() == CGamePlaygroundClientScriptAPI::ESpectatorTargetType::Single;

    switch (Api.GetSpectatorCameraType()) {
        case CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Free:
            camCurrent = Camera::Free;
            break;
        case CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow:
            camCurrent = single ? Camera::FollowSingle : Camera::FollowAll;
            break;
        case CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Replay:
            camCurrent = single ? Camera::ReplaySingle : Camera::FollowAll;
            break;
        default:
            camCurrent = Camera::None;
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
            UI::Text("Spectating: " + (spectating ? "\\$0F0true" : "\\$F00false"));
        if (S_TotalSpec && !cotd)
            UI::Text("Spectators in game: " + totalSpectators);

        UI::BeginDisabled(cotd || local);
        if (UI::Button("Toggle Spectating " + (Api.IsSpectatorClient ? Icons::ToggleOn : Icons::ToggleOff)))
            Api.RequestSpectatorClient(!Api.IsSpectatorClient);
        UI::EndDisabled();

        UI::Separator();

        UI::BeginDisabled(camCurrent == Camera::ReplaySingle || !spectating);
        if (UI::Button("Replay " + Icons::VideoCamera)) {
            if (loginLastViewed == "") {
                CGamePlayer@ Player = Playground.Players[0];
                if (Player.User.Login == loginLocal)
                    @Player = Playground.Players[1];
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
                CGamePlayer@ Player = Playground.Players[0];
                if (Player.User.Login == loginLocal)
                    @Player = Playground.Players[1];
                Api.SetSpectateTarget(Player.User.Login);
            } else
                Api.SetSpectateTarget(loginLastViewed);

            // https://github.com/ezio416/tm-spectator-camera/issues/3
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
