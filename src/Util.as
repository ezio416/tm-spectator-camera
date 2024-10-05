// c 2024-04-02
// m 2024-04-02

enum CameraType {
    Replay,
    FollowSingle,
    FollowAll,
    Free,
    None
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
