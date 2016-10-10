return {
  warFieldName = "贪 心 湾",
  authorName   = "RushFTK",
  playersCount = 2,

  width = 19,
  height = 15,

 layers = {
    {
      type = "tilelayer",
      name = "TileBase",
      x = 0,
      y = 0,
      width = 19,
      height = 15,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
1,1,1,1,59,55,61,57,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,41,48,1,50,61,57,1,1,1,59,61,55,62,1,1,
1,1,1,1,42,1,1,1,1,42,1,59,61,48,1,42,1,1,1,
1,1,1,1,50,57,1,1,1,41,61,48,1,1,59,48,1,1,1,
1,1,1,1,1,42,1,1,59,48,1,1,1,1,42,1,1,1,1,
1,1,1,1,59,48,1,1,42,1,1,1,1,59,48,1,1,1,1,
1,1,1,1,42,1,59,61,37,1,1,1,1,42,1,1,1,1,1,
1,1,1,1,50,55,48,1,50,61,57,1,59,46,57,1,1,1,1,
1,1,1,1,1,42,1,1,1,1,41,61,48,1,42,1,1,1,1,
1,1,1,1,59,48,1,1,1,1,42,1,1,59,48,1,1,1,1,
1,1,1,1,42,1,1,1,1,59,48,1,1,42,1,1,1,1,1,
1,1,1,59,48,1,1,59,61,37,1,1,1,50,57,1,1,1,1,
1,1,1,42,1,59,61,48,1,42,1,1,1,1,42,1,1,1,1,
1,1,63,46,61,48,1,1,1,50,61,57,1,59,37,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,50,61,46,48,1,1,1,1
      }
    },
    {
      type = "tilelayer",
      name = "TileObject",
      x = 0,
      y = 0,
      width = 19,
      height = 15,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
174,0,170,123,179,114,112,115,0,0,124,124,0,154,0,0,0,170,155,
147,123,125,0,114,117,185,116,189,115,0,1,185,114,112,115,179,123,124,
0,154,125,0,113,0,154,0,123,113,154,114,112,117,0,113,0,0,174,
104,0,0,154,116,115,0,0,154,120,190,117,0,154,114,117,0,154,0,
105,104,0,123,124,113,0,0,114,117,124,154,0,0,189,0,123,0,0,
124,106,0,125,114,117,125,154,113,0,150,0,0,114,117,124,104,125,0,
0,154,0,124,189,125,114,112,121,123,0,0,154,113,147,0,105,104,0,
0,103,154,0,116,118,117,124,116,189,115,124,114,119,115,0,154,106,0,
0,105,104,0,147,113,154,0,0,123,120,112,117,125,189,124,0,154,0,
0,125,105,124,114,117,0,0,151,0,113,154,125,114,117,125,0,103,124,
0,0,123,0,189,0,0,154,124,114,117,0,0,113,124,123,0,105,104,
0,154,0,114,117,154,0,114,191,121,154,0,0,116,115,154,0,0,105,
174,0,0,113,0,114,112,117,154,113,123,0,154,0,113,0,125,154,0,
124,123,179,116,112,117,186,1,0,116,189,115,186,114,117,0,125,123,147,
156,171,0,0,0,154,0,124,124,0,0,116,112,117,179,123,171,0,174
      }
    },
    {
      type = "tilelayer",
      name = "Unit",
      x = 0,
      y = 0,
      width = 19,
      height = 15,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,211,0,0
      }
    }
  }
}