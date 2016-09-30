return {
  warFieldName = "炼 狱 圣 坛",
  authorName   = "RushFTK",
  playersCount = 2,

  width = 19,
  height = 19,
  layers = {
    {
      type = "tilelayer",
      name = "TileBase",
      x = 0,
      y = 0,
      width = 19,
      height = 19,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        18, 18, 18, 18, 19, 43, 47, 1, 1, 1, 1, 1, 49, 43, 22, 18, 18, 18, 18,
        18, 18, 19, 43, 47, 1, 1, 1, 1, 1, 1, 1, 1, 1, 49, 43, 22, 18, 18,
        18, 19, 47, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 49, 22, 18,
        18, 34, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 38, 18,
        19, 47, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 49, 22,
        34, 1, 1, 1, 1, 1, 1, 1, 59, 61, 57, 1, 1, 1, 1, 1, 1, 1, 38,
        47, 1, 1, 1, 1, 1, 59, 48, 1, 1, 1, 50, 57, 1, 1, 1, 1, 1, 49,
        1, 1, 1, 1, 1, 1, 48, 1, 1, 1, 1, 1, 50, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 59, 1, 1, 1, 1, 1, 1, 1, 57, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 42, 1, 1, 1, 64, 1, 1, 1, 42, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 49, 1, 1, 1, 1, 1, 1, 1, 48, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 57, 1, 1, 1, 1, 1, 59, 1, 1, 1, 1, 1, 1,
        56, 1, 1, 1, 1, 1, 50, 57, 1, 1, 1, 59, 48, 1, 1, 1, 1, 1, 58,
        34, 1, 1, 1, 1, 1, 1, 1, 50, 61, 48, 1, 1, 1, 1, 1, 1, 1, 38,
        20, 56, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 58, 26,
        18, 34, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 38, 18,
        18, 20, 56, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 58, 26, 18,
        18, 18, 20, 52, 56, 1, 1, 1, 1, 1, 1, 1, 1, 1, 58, 52, 26, 18, 18,
        18, 18, 18, 18, 20, 52, 56, 1, 1, 1, 1, 1, 58, 52, 26, 18, 18, 18, 18
      }
    },
    {
      type = "tilelayer",
      name = "TileObject",
      x = 0,
      y = 0,
      width = 19,
      height = 19,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        104, 104, 104, 104, 0, 0, 0, 0, 130, 0, 0, 102, 0, 0, 0, 104, 104, 104, 104,
        104, 104, 0, 0, 0, 99, 130, 0, 101, 0, 0, 99, 145, 0, 0, 0, 0, 104, 104,
        104, 0, 0, 0, 81, 80, 0, 0, 0, 100, 0, 0, 0, 0, 130, 0, 0, 0, 104,
        104, 0, 0, 0, 0, 78, 0, 0, 0, 99, 101, 0, 0, 147, 0, 0, 0, 0, 104,
        0, 0, 130, 0, 0, 81, 80, 125, 0, 0, 100, 130, 0, 101, 0, 0, 79, 0, 0,
        0, 0, 0, 146, 101, 0, 81, 130, 0, 89, 0, 100, 102, 0, 79, 77, 82, 99, 0,
        0, 145, 0, 0, 0, 102, 0, 0, 100, 102, 103, 0, 0, 79, 82, 0, 0, 130, 0,
        102, 99, 0, 0, 130, 100, 0, 99, 130, 0, 81, 99, 0, 130, 125, 0, 0, 0, 0,
        0, 0, 0, 101, 100, 0, 103, 82, 0, 0, 0, 130, 100, 0, 0, 0, 0, 101, 130,
        0, 0, 100, 99, 0, 88, 102, 0, 0, 0, 0, 0, 102, 88, 0, 99, 100, 0, 0,
        130, 101, 0, 0, 0, 0, 100, 130, 0, 0, 0, 79, 103, 0, 100, 101, 0, 0, 0,
        0, 0, 0, 0, 125, 130, 0, 99, 80, 0, 130, 99, 0, 100, 130, 0, 0, 99, 102,
        0, 130, 0, 0, 79, 82, 0, 0, 103, 102, 100, 0, 0, 102, 0, 0, 0, 145, 0,
        0, 99, 79, 77, 82, 0, 102, 100, 0, 89, 0, 130, 80, 0, 101, 146, 0, 0, 0,
        0, 0, 82, 0, 0, 101, 0, 130, 100, 0, 0, 125, 81, 80, 0, 0, 130, 0, 0,
        104, 0, 0, 0, 0, 147, 0, 0, 101, 99, 0, 0, 0, 78, 0, 0, 0, 0, 104,
        104, 0, 0, 0, 130, 0, 0, 0, 0, 100, 0, 0, 0, 81, 80, 0, 0, 0, 104,
        104, 104, 0, 0, 0, 0, 145, 99, 0, 0, 101, 0, 130, 99, 0, 0, 0, 104, 104,
        104, 104, 104, 104, 0, 0, 0, 102, 0, 0, 130, 0, 0, 0, 0, 104, 104, 104, 104
      }
    },
    {
      type = "tilelayer",
      name = "Unit",
      x = 0,
      y = 0,
      width = 19,
      height = 19,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 187, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      }
    }
  }
}
