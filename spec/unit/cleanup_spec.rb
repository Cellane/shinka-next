require 'shinka/commands/cleanup'

RSpec.describe Shinka::Commands::Cleanup do
  it "executes `cleanup` command successfully" do
    output = StringIO.new
    options = {}
    command = Shinka::Commands::Cleanup.new(options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
