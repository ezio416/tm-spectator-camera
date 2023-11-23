/*
c 2023-11-22
m 2023-11-22
*/

void RenderDev() {
    if (!S_Dev)
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

    UI::Begin("SpecCamDev", UI::WindowFlags::AlwaysAutoResize);
        UI::Text("spec: " + Api.IsSpectator);
        UI::Text("specClient: " + Api.IsSpectatorClient);
        UI::Text("ForceSpectator: " + Client.ForceSpectator);
        UI::Text("ForceCamType: " + Client.SpectatorForceCameraType);
        UI::Text("camType: " + tostring(Api.GetSpectatorCameraType()));
        UI::Text("targetType: " + tostring(Api.GetSpectatorTargetType()));

        if (UI::Button("toggle spec"))
            Api.RequestSpectatorClient(!Api.IsSpectatorClient);

        if (UI::Button("toggle force spec"))
            Client.ForceSpectator = !Client.ForceSpectator;

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
            auto Player = cast<CGamePlayer@>(Playground.Players[i]);
            if (UI::Selectable(Player.User.Name + " " + Player.User.Login, false)) {
                Api.SetSpectateTarget(Player.User.Login);
                Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
            }
        }
    UI::End();
}