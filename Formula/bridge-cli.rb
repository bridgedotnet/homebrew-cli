# Documentation: https://docs.brew.sh/Formula-Cookbook.html
#                http://www.rubydoc.info/github/Homebrew/brew/master/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class BridgeCli < Formula
  desc "Bridge.NET CLI"
  homepage "https://bridge.net/"
  url "https://github.com/bridgedotnet/CLI.git", :tag => "v0.1-alpha"
  version "0.1-alpha"

  #devel do
  #  url "https://github.com/bridgedotnet/CLI.git", :branch => "master"
  #end

  # if tar/gz is desired
  #url "https://github.com/bridgedotnet/CLI/tarball/v0.1-alpha"
  #sha256 "010b8456d1fbec98cbbbebba07509124799d23f3823931f956bfd3fc0247cb8a"

  depends_on "mono" => :run

  def install
    # ENV.deparallelize  # if your formula fails when building in parallel

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

    system bin/"bridge"
  end
end
