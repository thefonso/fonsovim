module Fonsovim
  # Errors
  FonsovimError = Class.new Exception
  BlockNotGivenError = Class.new FonsovimError
  RubyGemsNotFoundError = Class.new FonsovimError
end
