-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    dir = '~/.config/nvim/lua/custom/plugins/floaterminal.nvim',
    config = function()
      require 'floaterminal'
    end,
  },
  { dir = '~/.config/nvim/lua/custom/plugins/present.nvim' },
}
