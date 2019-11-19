MIN_MONO_VER="5.18.0".freeze
MIN_MSBUILD_VER="16.0".freeze
MIN_XBUILD_VER="14.0".freeze

class Bridge < Formula
  desc "Bridge.NET CLI"
  homepage "https://bridge.net/"
  url "https://github.com/bridgedotnet/CLI.git", :tag => "v17.10.1"

  # Currently, the development branch is 'master'.
  head "https://github.com/bridgedotnet/CLI.git", :branch => "master"

  bottle do
    root_url "https://github.com/bridgedotnet/homebrew-cli/releases/download/bottle"
    sha256 "22998c84ab7d3aec67f0fd0684c1d9aabe8da5bf06c2c06a9ec17f9c5b6eecee" => :sierra
    sha256 "378d65394b9040ad61f0b645002cee7136bd8ccdbd1df6c4cc27a8689adfeebf" => :high_sierra
    sha256 "1b424764e880bf38b8b0a5e415d5feb7c7b73d577bb95bda36a4ad304fa40d51" => :catalina
    cellar :any_skip_relocation
  end

  # Building from sources from the dev branch shouldn't work unless all other
  # packages (that are probably not released to NuGet) are built and placed in
  # a local NuGet location, so a much much more complex build process should
  # take place here.
  # devel do
  #  url "https://github.com/bridgedotnet/CLI.git", :branch => "dev"
  # end

  # #if tar/gz is desired
  # url "https://github.com/bridgedotnet/CLI/tarball/v0.1-alpha"
  # sha256 "010b8456d1fbec98cbbbebba07509124799d23f3823931f956bfd3fc0247cb8a"

  class << self
    def mono?
      # Favor brew formula if it is installed.
      # This allows depends_on to kick in and set up paths as well.
      if Formula["mono"].bin.exist?
        false
      elsif which_mono = fp("mono")
        version = Utils.popen_read which_mono, "--version", :err => :out
        return false unless $CHILD_STATUS.success?
        version = version[/Mono JIT compiler version (\d+.\d+.\d+).*/, 1]
        return false unless version
        Version.new(version) >= MIN_MONO_VER
      else
        false
      end
    end

    def msbuild?
      return false unless mono?
      if which_msbuild = fp("msbuild")
        version = Utils.popen_read which_msbuild, "/version", :err => :out
        return false unless $CHILD_STATUS.success?
        version = version[/Microsoft \(R\) Build Engine version (\d+.\d+.\d+).*/, 1]
        return false unless version
        Version.new(version) >= MIN_MSBUILD_VER
      else
        false
      end
    end

    def xbuild?
      return false unless mono?
      if which_xbuild = fp("xbuild")
        version = Utils.popen_read which_xbuild, "/version", :err => :out
        return false unless $CHILD_STATUS.success?
        version = version[/XBuild Engine version (\d+.\d+).*/, 1]
        return false unless version
        Version.new(version) >= MIN_XBUILD_VER
      else
        false
      end
    end

    def fp(what)
      which(what, ENV["HOMEBREW_PATH"])
    end
  end

  depends_on "mono" unless mono?
  depends_on "mono" => :build unless msbuild? || xbuild?

  def install
    # If we have paths.d, then load paths from it, as mono package sets up its
    # path there.
    pathsd_directory = Pathname.new("/etc/paths.d")
    pathsd_directory.children.each do |child|
      ENV.append_path "PATH", child.readlines.collect(&:strip).join(":")
    end
    ENV.append_path "PATH", ":/usr/local/bin"

    # By default, builder path is to /bin/false so that it returns an error.
    builder = "false"

    # Favor msbuild over xbuild.
    if which("msbuild")
      builder = "msbuild"
    elsif which("xbuild")
      builder = "xbuild"
    end

    system builder, "/p:Configuration=Release", "Bridge.CLI.sln"

    Dir.chdir("Bridge/bin/Release") do
      libexec.install("bridge.exe")
      libexec.install("templates")
      libexec.install("tools")

      # Create a bridge wrapper to call it using mono
      (bin/"bridge").write <<~EOS
        #!/bin/bash

        scppath="$(dirname "${BASH_SOURCE[0]}")"

        # In OSX we can only get relative path to the link.
        physpath="$(dirname "$(readlink -n "${BASH_SOURCE[0]}")")"
        bridgepath="${scppath}/${physpath}/../libexec/bridge.exe"

        mono "${bridgepath}" "${@}"

        exit "${?}"
      EOS
    end
  end

  test do
    # `test do` will create, run in and delete a temporary directory.

    system bin/"bridge", "new"
    system bin/"bridge", "build"
  end
end
