#if SIG_DEVELOPER

void RenderDev() {
    if (!S_Dev)
        return;

    auto App = cast<CTrackMania>(GetApp());
    auto Playground = cast<CSmArenaClient>(App.CurrentPlayground);
    auto Network = cast<CTrackManiaNetwork>(App.Network);

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

    UI::Begin("SpecCamDev", S_Dev, UI::WindowFlags::AlwaysAutoResize);
        UI::Text("spec: " + Api.IsSpectator);
        UI::Text("specClient: " + Api.IsSpectatorClient);
        // UI::Text("ForceSpectator: " + Client.ForceSpectator);
        // UI::Text("ForceCamType: " + Client.SpectatorForceCameraType);
        UI::Text("camType: " + tostring(Api.GetSpectatorCameraType()));
        UI::Text("targetType: " + tostring(Api.GetSpectatorTargetType()));
        // UI::Text("script: " + (Script is null ? "false" : "true"));
        UI::Text("spec: " + (spectating ? "true" : "false"));
        UI::Text("login: " + loginLocal);
        UI::Text("viewing: " + loginViewing);
        UI::Text("lastViewed: " + loginLastViewed);

        if (UI::Button("toggle spec"))
            Api.RequestSpectatorClient(!Api.IsSpectatorClient);

        // if (UI::Button("toggle force spec"))
        //     Client.ForceSpectator = !Client.ForceSpectator;

        if (UI::Button("set replay"))
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Replay);

        if (UI::Button("set follow"))
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);

        if (UI::Button("set free"))
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Free);

        if (UI::Button("follow all")) {
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
            Client.Spectator_SetForcedTarget_AllPlayers();
        }

        if (UI::Button("follow single")) {
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
            Client.Spectator_SetForcedTarget_Clear();
        }

        for (uint i = 0; i < Playground.Players.Length; i++) {
            CGamePlayer@ Player = Playground.Players[i];
            if (UI::Selectable(Player.User.Name + " " + Player.User.Login, false)) {
                Api.SetSpectateTarget(Player.User.Login);
                Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
            }
        }
    UI::End();
}

#endif
