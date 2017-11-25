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
      #recursive_install("templates", libexec)
      #recursive_install("tools", libexec)
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

  def recursive_install(source, destination)
    print("Checkup metafiles from '"+source+"' to '"+destination+"'.\n")
    print("Install metafiles from '"+source+"' to '"+destination+"'.\n")

    # We install first and recurse later, else it will install to a subdirectory
    # with the same name.
    Pathname(destination.to_s).install(source)
    Pathname(source).subdirs.each do |subpath|
      # Just the immediate upper directory part of the path
      #new_dest = destination.to_s + "/" + File.basename(File.dirname(subpath))
      new_dest = destination.to_s
      print("Recursing into '"+subpath+"': "+new_dest+"\n")
      recursive_install(subpath, new_dest)
    end

  end
end
