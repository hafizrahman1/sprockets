# -*- coding: utf-8 -*-
require 'sprockets_test'
require 'sprockets/path_utils'

class TestPathUtils < Sprockets::TestCase
  include Sprockets::PathUtils

  DOSISH = File::ALT_SEPARATOR != nil
  DOSISH_DRIVE_LETTER = File.dirname("A:") == "A:."
  DOSISH_UNC = File.dirname("//") == "//"

  test "stat" do
    assert_kind_of File::Stat, stat(FIXTURE_ROOT)
    refute stat("/tmp/sprockets/missingfile")
  end

  test "file?" do
    assert_equal true, file?(File.join(FIXTURE_ROOT, 'default', 'hello.txt'))
    assert_equal false, file?(FIXTURE_ROOT)
  end

  test "entries" do
    assert_equal [
      "asset",
      "compass",
      "context",
      "default",
      "directives",
      "encoding",
      "engines",
      "errors",
      "octicons",
      "paths",
      "public",
      "resolve",
      "sass",
      "server",
      "symlink"
    ], entries(FIXTURE_ROOT)
  end

  test "check absolute path" do
    assert absolute_path?(Dir.pwd)

    assert absolute_path?("/foo.rb")
    refute absolute_path?("foo.rb")
    refute absolute_path?("./foo.rb")
    refute absolute_path?("../foo.rb")

    if DOSISH_DRIVE_LETTER
      assert absolute_path?("A:foo.rb")
      assert absolute_path?("A:/foo.rb")
      assert absolute_path?("A:\\foo.rb")
    end

    if DOSISH
      assert absolute_path?("/foo.rb")
      assert absolute_path?("\\foo.rb")
    end
  end

  test "check relative path" do
    assert relative_path?(".")
    assert relative_path?("..")
    assert relative_path?("./")
    assert relative_path?("../")
    assert relative_path?("./foo.rb")
    assert relative_path?("../foo.rb")

    if DOSISH
      assert relative_path?(".\\")
      assert relative_path?("..\\")
      assert relative_path?(".\\foo.rb")
      assert relative_path?("..\\foo.rb")
    end

    refute relative_path?(Dir.pwd)
    refute relative_path?("/foo.rb")
    refute relative_path?("foo.rb")
    refute relative_path?(".foo.rb")
    refute relative_path?("..foo.rb")
  end

  test "split subpath from root path" do
    assert_equal "application.js",
      split_subpath(fixture_path("default"), fixture_path("default/application.js"))
    assert_equal "application.js",
      split_subpath(fixture_path("default") + "/", fixture_path("default/application.js"))
    assert_equal "app/application.js",
      split_subpath(fixture_path("default"), fixture_path("default/app/application.js"))
    refute split_subpath(fixture_path("default"), fixture_path("other/app/application.js"))
  end

  test "split paths root from base" do
    assert_equal [fixture_path("default"), "application.js"],
      paths_split([fixture_path("default")], fixture_path("default/application.js"))
    assert_equal [fixture_path("default"), "app/application.js"],
      paths_split([fixture_path("default")], fixture_path("default/app/application.js"))
    refute paths_split([fixture_path("default")], fixture_path("other/app/application.js"))
  end

  test "path extensions" do
    assert_equal [".txt"], path_extnames("hello.txt")
    assert_equal [".txt"], path_extnames("sub/hello.txt")
    assert_equal [".txt"], path_extnames("sub.dir/hello.txt")
    assert_equal [".js"], path_extnames("jquery.js")
    assert_equal [".min", ".js"], path_extnames("jquery.min.js")
    assert_equal [".js", ".erb"], path_extnames("jquery.js.erb")
    assert_equal [".min", ".js", ".erb"], path_extnames("jquery.min.js.erb")
  end

  test "path parents" do
    root = File.expand_path("../..", __FILE__)

    assert_kind_of Array, path_parents(File.expand_path(__FILE__))

    assert_equal ["#{root}/test", root],
      path_parents(File.expand_path(__FILE__), root)
    assert_equal ["#{root}/test", root],
      path_parents(fixture_path(""), root)
    assert_equal ["#{root}/test/fixtures", "#{root}/test", root],
      path_parents(fixture_path("default"), root)
    assert_equal ["#{root}/test/fixtures/default", "#{root}/test/fixtures", "#{root}/test", root],
      path_parents(fixture_path("default/POW.png"), root)

    assert_equal ["#{root}/test/fixtures/default", "#{root}/test/fixtures", "#{root}/test"],
      path_parents(fixture_path("default/POW.png"), "#{root}/test")
    assert_equal ["#{root}/test/fixtures/default"],
      path_parents(fixture_path("default/POW.png"), "#{root}/test/fixtures/default")
  end

  test "find upwards" do
    root = File.expand_path("../..", __FILE__)

    assert_equal "#{root}/Gemfile",
      find_upwards("Gemfile", File.expand_path(__FILE__))
    assert_equal "#{root}/Gemfile",
      find_upwards("Gemfile", fixture_path(""))
    assert_equal "#{root}/Gemfile",
      find_upwards("Gemfile", fixture_path("default/POW.png"))

    assert_equal "#{root}/test/sprockets_test.rb",
      find_upwards("sprockets_test.rb", fixture_path("default/POW.png"))
  end

  FILES_IN_DEFAULT = Dir["#{FIXTURE_ROOT}/default/*"].size

  test "stat directory" do
    assert_equal FILES_IN_DEFAULT, stat_directory(File.join(FIXTURE_ROOT, "default")).to_a.size
    path, stat = stat_directory(File.join(FIXTURE_ROOT, "default")).first
    assert_equal fixture_path("default/app"), path
    assert_kind_of File::Stat, stat

    assert_equal [], stat_directory(File.join(FIXTURE_ROOT, "missing")).to_a
  end

  SYMLINKS_UNDER_DEFAULT = 6
  FILES_UNDER_DEFAULT = Dir["#{FIXTURE_ROOT}/default/**/*"].size + SYMLINKS_UNDER_DEFAULT

  test "stat tree" do
    assert_equal FILES_UNDER_DEFAULT, stat_tree(File.join(FIXTURE_ROOT, "default")).to_a.size
    path, stat = stat_tree(File.join(FIXTURE_ROOT, "default")).first
    assert_equal fixture_path("default/app"), path
    assert_kind_of File::Stat, stat

    assert_equal [], stat_tree(File.join(FIXTURE_ROOT, "missing")).to_a
  end

  test "atomic write without errors" do
    filename = "atomic.file"
    begin
      contents = "Atomic Text"
      atomic_write(filename) do |file|
        file.write(contents)
        assert !File.exist?(filename)
      end
      assert File.exist?(filename)
      assert_equal contents, File.read(filename)
    ensure
      File.unlink(filename) rescue nil
    end
  end
end
