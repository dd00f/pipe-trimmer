arrow = util.table.deepcopy(data.raw["arrow"]["orange-arrow-with-circle"])
arrow.name = "orphan-arrow"
arrow.circle_picture =
{
  filename = "__pipe-trimmer__/graphics/large-orange-circle.png",
  priority = "low",
  width = "64",
  height = "64"
}

data:extend({
  arrow,
  {
    type = "custom-input",
    name = "find-orphans",
    key_sequence = "SHIFT + O"
  }
})

data:extend({
  arrow,
  {
    type = "custom-input",
    name = "delete-orphans",
    key_sequence = "SHIFT + P"
  }
})

data:extend({
  arrow,
  {
    type = "custom-input",
    name = "find-cheats",
    key_sequence = "SHIFT + I"
  }
})