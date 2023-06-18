public struct Size {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        assert(width > 0)
        assert(height > 0)

        self.width = width
        self.height = height
    }
}
