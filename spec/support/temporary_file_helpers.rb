require 'pathname'

module TemporaryFileHelpers
  def in_temporary_path(*args)
    Pathname.pwd.join("tmp/spec", *args).tap do |path|
      path.basename.mkpath
      yield(path) if block_given?
    end
  end
end
