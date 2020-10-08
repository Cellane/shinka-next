RSpec.describe "`shinka cleanup` command", type: :cli do
  it "executes `shinka help cleanup` command successfully" do
    output = `shinka help cleanup`
    expected_output = <<-OUT
Usage:
  shinka cleanup

Options:
  -h, [--help], [--no-help]  # Display usage information

Command description...
    OUT

    expect(output).to eq(expected_output)
  end
end
