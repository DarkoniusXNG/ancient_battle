codes = true
ranges = true
cache = true
max_line_length = 200
allow_defined_top = true

globals = { -- these globals can be set and accessed.
"GameRules",
}

read_globals = { -- these globals can only be accessed.
"PrintTable",
"HideWearables",
"ShowWearables",
}

ignore = {
  -- "111", -- setting non-standard global variable
  -- "112", -- mutating non-standard global variable
  "131", -- unused global variable
  "211", -- unused variable
  "212", -- unused argument
  "213", -- unused loop variable
  "231", -- never accessed
  "311", -- Value assigned to a local variable is unused.
  "631", -- line is too long (200)
}

-- enable warnings to make sure they're alway checked
enable = {
}

exclude_files = {
  
}
files["**/vscripts/units/**/*.lua"].globals = { "thisEntity" }
