MIN_MONO_VER="5.4.1"
MIN_MSBUILD_VER="15.4"

class Bridge < Formula
  desc "Bridge.NET CLI"
  homepage "https://bridge.net/"
  url "https://github.com/bridgedotnet/CLI.git", :tag => "v16.6.1-pre"
  # version "16.6.1"

  # Currently, the development branch is 'master'.
  head "https://github.com/bridgedotnet/CLI.git", :branch => "master"

  bottle do
    root_url "https://github.com/bridgedotnet/CLI/releases/download/v16.6.1-pre"
    cellar :any_skip_relocation
    sha256 "94471ca9c1837896368330341b4374bf82ab7015c855ee0ee958d047492f3549" => :high_sierra
  end

  # devel do
  #  url "https://github.com/bridgedotnet/CLI.git", :branch => "master"
  # end

  # #if tar/gz is desired
  # url "https://github.com/bridgedotnet/CLI/tarball/v0.1-alpha"
  # sha256 "010b8456d1fbec98cbbbebba07509124799d23f3823931f956bfd3fc0247cb8a"

  class << self
    def has_mono?
      if which_mono = which("mono", ENV["HOMEBREW_PATH"])
        version = Utils.popen_read which_mono, "--version", err: :out
        return false unless $CHILD_STATUS.success?
        version = version[/Mono JIT compiler version (\d+.\d+.\d+).*/, 1]
        return false unless version
        Version.new(version) >= MIN_MONO_VER
      else
        false
      end
    end

    def has_msbuild?
      return false unless has_mono?
      if which_msbuild = which("msbuild", ENV["HOMEBREW_PATH"])
        version = Utils.popen_read which_msbuild, "/version", err: :out
        return false unless $CHILD_STATUS.success?
        version = version[/Microsoft \(R\) Build Engine version (\d+.\d+.\d+).*/, 1]
        return false unless version
        Version.new(version) >= MIN_MSBUILD_VER
      else
        false
      end
    end
  end

  depends_on "bridgedotnet/cli/mono" => :run unless has_mono?
  depends_on "bridgedotnet/cli/mono" => :build unless has_msbuild?

  def install
    system "xbuild", "/p:Configuration=Release", "Bridge.CLI.sln"

    Dir.chdir("Bridge/bin/Release") do
      libexec.install("bridge.exe")
      libexec.install("templates")
      libexec.install("tools")

      # Create a bridge wrapper to call it using mono
      bridge_wrapper = File.new("bridge", "w")
      bridge_wrapper.puts "#!/bin/bash

scppath=\"$(dirname \"${BASH_SOURCE[0]}\")\"

# In OSX we can only get relative path to the link.
physpath=\"$(dirname \"$(readlink -n \"${BASH_SOURCE[0]}\")\")\"
bridgepath=\"${scppath}/${physpath}/../libexec/bridge.exe\"

mono \"${bridgepath}\" \"${@}\"

exit ${!}"
      bridge_wrapper.close

      bin.install("bridge")
    end
  end

  test do
    # `test do` will create, run in and delete a temporary directory.

    system bin/"bridge", "new"
    system bin/"bridge", "build"
  end
end
