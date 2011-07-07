require 'fileutils'

verbose = false

from = ARGV.shift or abort "need source directory"
to   = ARGV.shift or abort "need target directory"

exclude = ARGV

from = File.expand_path(from)
to   = File.expand_path(to)

Dir.chdir(from) do
  FileUtils.mkdir_p(to)
  queue = Dir.glob("*", File::FNM_DOTMATCH)
  while queue.any?
    item = queue.shift
    name = File.basename(item)

    next if name == "." || name == ".."
    next if exclude.any? { |pattern| File.fnmatch(pattern, item) }

    source = File.join(from, item)
    target = File.join(to, item)

    if File.symlink?(item)
      FileUtils.ln_s(File.readlink(source), target)
    elsif File.directory?(item)
      queue += Dir.glob("#{item}/*", File::FNM_DOTMATCH)
      FileUtils.mkdir_p(target, :mode => File.stat(item).mode)
    else
      FileUtils.ln(source, target)
    end
  end
end
