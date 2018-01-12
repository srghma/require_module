module RequireModule
  def require_module_relative(path, **options)
    caller_filepath = caller_locations(1..1).first.absolute_path
    caller_dir = File.dirname(caller_filepath)

    fullpath = File.expand_path(path, caller_dir)

    require_module(fullpath, **options)
  end

  def require_module(fullpath, cache: true)
    with_ext    = add_ext(fullpath)
    without_ext = rem_ext(fullpath)

    content = read_rb(with_ext)

    if cache
      constant_name = without_ext.gsub(%r{[/\.]}, '_').split('_').map(&:capitalize).join.to_sym
      begin
        Object.const_get(constant_name)
      rescue NameError
        mod = gen_mod(content)
        Object.const_set(constant_name, mod)
        mod
      end
    else
      gen_mod(content)
    end
  end

  private

  def gen_mod(content)
    Module.new.tap do |mod|
      mod.module_eval(content)
    end
  end

  def read_rb(fullpath)
    File.read(fullpath)
  rescue Errno::ENOENT
    raise LoadError, "path doesn't exist at #{fullpath}"
  end

  def add_ext(path)
    Pathname.new(path).sub_ext('.rb').to_s
  end

  def rem_ext(path)
    path.sub(/#{File.extname(path)}$/, '')
  end
end

include RequireModule