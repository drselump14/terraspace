class Terraspace::CLI
  class CheckSetup
    extend Memoist

    # Terraspace requires at least this version of terraform
    REQUIRED_TERRAFORM_VERSION = "0.12"

    def initialize(options={})
      @options = options
    end

    # Used for the CLI
    def run
      puts "Detected Terrspace version: #{Terraspace::VERSION}"
      if terraform_bin
        puts "Detected Terraform bin: #{terraform_bin}"
        puts "Detected #{terraform_version_message}"
        check_required_version!
      else
        puts "Terraform not installed. Unable to detect a terraform command. Please double check that terraform is installed."
        exit 1
      end
    end

    def check_required_version!
      puts "Terraspace requires Terraform v#{REQUIRED_TERRAFORM_VERSION}.x and above"
      if ok?
        puts "You're all set!"
      else
        puts "The installed version of terraform may not work with terraspace."
        puts "Recommend using at least terraform v#{REQUIRED_TERRAFORM_VERSION}.x"
        puts "If you would like to bypass this check. Use TS_VERSION_CHECK=0" unless check_command?
        exit 1 unless ENV['TS_VERSION_CHECK'] == '0'
      end
    end

    def check_command?
      ARGV[0] == "check_setup"
    end

    def ok?
      version = terraform_version_message.sub(/.*v/,'') # => 0.12.24
      major, minor, _ = version.split('.')
      required_major, required_minor = REQUIRED_TERRAFORM_VERSION.split('.')
      x = major.to_i >= required_major.to_i
      y = minor.to_i >= required_minor.to_i
      x && y
    end

    def terraform_bin
      bin_path = `which terraform 2>&1`.strip
      bin_path if $?.success?
    end
    memoize :terraform_bin

    # Sometimes Terraform shows the version info on the first line and sometimes on the bottom line.
    # Account for that by finding the line.
    #
    #     $ terraform --version
    #     Terraform v0.12.24
    #
    #     Your version of Terraform is out of date! The latest version
    #     is 0.12.26. You can update by downloading from https://www.terraform.io/downloads.html
    #
    def terraform_version_message
      `terraform --version`.split("\n").find { |l| l =~ /^Terraform / }.strip
    end
    memoize :terraform_version_message

    class << self
      # Used as library call
      def check!
        setup = new
        return if setup.ok?
        # run meth designed for CLI and will puts out informative messages about installed version and exit 1 when version is not ok
        setup.run
      end
    end
  end
end
