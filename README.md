# Luhn Algorithm for Credit Card Validation in Ruby

An implementation of the Luhn algorithm for validating credit cards written in Ruby and using RSpec for testing. This demonstrates how to maintain an account balance while processing and screeening credit card transactions.

For more on the Luhn algorithm: https://en.wikipedia.org/wiki/Luhn_algorithm


## Overview of the Directory
  ```
  - Gemfile  
  - Gemfile.lock  
  - lib
        - account.rb            'Contains the Account Class'
        - card.rb               'Contains the Credit Card Class'
        - logging.rb            'Holds generic logging wrapper for extending with rsyslog' 
        - payment_processor.rb  'Holds the Payment Processing and Reporting Class'
        - run_processor.rb      'This is the driver script for running the simulation'
  - README.md  
  - README
  - spec  
        - account_spec.rb   'Account tests'
        - card_spec.rb      'Card tests'
        - input_1.txt       'Test Input File 1'
        - input_2.txt       'Test Input File 2'
        - input_3.txt       'Test Input File 3'
        - input_4.txt       'Test Input File 4'
        - input_5.txt       'Test Input File 5'
        - input_6.txt       'Test Input File 6'
        - input_7.txt       'Test Input File 7'
        - input_8.txt       'Test Input File 8'
        - input_9.txt       'Test Input File 9'
        - output_1.txt      'Test Output File 1'
        - output_2.txt      'Test Output File 2'
        - output_3.txt      'Test Output File 3'
        - output_4.txt      'Test Output File 4'
        - output_5.txt      'Test Output File 5'
        - output_6.txt      'Test Output File 6'
        - output_7.txt      'Test Output File 7'
        - output_8.txt      'Test Output File 8'
        - output_9.txt      'Test Output File 9'
        - payment_processor_spec.rb 'Processing and simulation tests'
        - spec_helper.rb 
  - SPECS.md
  ```

## Design Details

This repository uses 3 classes to handle validating credit cards and updating account balances. The general control flow is:

    run_processor (Determine Input Mode: STDIN or single-file)
        
        - Add     -> PaymentProcessor -> New Account  -> Card (Most Recent Payment Source)
        - Charge  -> PaymentProcessor -> Find Account -> Card (Most Recent Payment Source)
        - Credit  -> PaymentProcessor -> Find Account -> Card (Most Recent Payment Source)
        - Summary -> PaymentProcessor -> All Accounts -> Card Balances/State (Most Recent Payment Source)

## Class and File Overview

##### run_processor

- This is a simple STDIN/file driver that determines input. Based off the presence of an additional single argument, the control flow will automate reading and processing the file or let the user type input commands to STDIN. Other notes, I decided not to use OptionParser because it was easier with the simple argument requirements. I also included a debug flag -d to help debug future enhancements/extensions for single-file input mode.

##### PaymentProcessor
        
- This class maintains all accounts and performs the summary output report at the end of processing. It is the driving interface for the Add, Charge, and Credit commands. I used a factory method approach with the process_action method so I could extend functionality to both the STDIN and single-file input modes.

##### Account
        
- This class maintains all cards used by the assigned name, general status, account balance, account limit, and default payment source. It aggregates Card objects and abstracts their methods from the PaymentProcessor while handling detection if the Account is in a general error state via the is_valid? method.

##### Card

- This class maintains the card number, luhn check, card balance, card limits, and card status.


## Assumptions:

This build was tested with Ruby 1.9.3p327 and Fedora 17 installed:

``` 
$ ruby -v
ruby 1.9.3p327 (2012-11-10 revision 37606) [x86_64-linux]
$
```

``` 
$ uname -r
3.6.7-4.fc17.x86_64
$
```

- The tests are written for usage with rspec. Due to the natue of the STDIN, I automated two tests in the spec/payment_processor_spec.rb that use shell scripting with the ruby 'system' method which uses a command that assumes the appropriate ruby is in the user's PATH and that /tmp/ is writeable and readable by the testing user.

Here is my rvm ruby:
```
$ which ruby
~/.rvm/rubies/ruby-1.9.3-p327/bin/ruby
$
```

I assumed that an account that has a valid card (even with a balance) and then tries to add an invalid card based off Luhn 10 or another fraud screen will return an "error" on the Account's summary. I assumed that accounts that add a valid card after having a valid card that has charged/credited a balance is replaced as the default payment source and only the latest card will appear in the summary report for balance purposes.

## Installation

1.  Install the gems with: bundle install

    ```
    $ ls
    Gemfile  Gemfile.lock  lib  path  README  README.md  spec  SPECS.md
    $ bundle install
    Fetching gem metadata from https://rubygems.org/.........
    Installing colorize (0.7.7) 
    Installing diff-lcs (1.2.5) 
    Installing json (1.8.3) with native extensions 
    Installing rdoc (4.2.0) 
    Installing rspec-support (3.3.0) 
    Installing rspec-core (3.3.2) 
    Installing rspec-expectations (3.3.1) 
    Installing rspec-mocks (3.3.2) 
    Installing rspec (3.3.0) 
    Using bundler (1.2.2) 
    Your bundle is complete! It was installed into ./path
    Post-install message from rdoc:
    Depending on your version of ruby, you may need to install ruby rdoc/ri data:

    <= 1.8.6 : unsupported
     = 1.8.7 : gem install rdoc-data; rdoc-data --install
     = 1.9.1 : gem install rdoc-data; rdoc-data --install
    >= 1.9.2 : nothing to do! Yay!
    $
    ```

1. Run the tests with: bundle exec rspec

    ```
    $ bundle exec rspec
    ........................

    Finished in 3.1 seconds (files took 0.12666 seconds to load)
    24 examples, 0 failures

    $ 
    ```

1. Display the usage help for the run_processor.rb file found in the lib directory: 

    ```
    $ cd lib
    $ ruby run_processor.rb help
     
        Usage Help for Payment Processing

            To run in interactive mode use this command:
                ruby-luhn-checker-for-credit-card-validation/lib$ ruby run_processor.rb        

            To perform the transactions listed inside a file use this command:
                ruby-luhn-checker-for-credit-card-validation/lib$ ruby run_processor.rb <PATH TO INPUT FILE>

    $
    ```

## Validating Credit Cards

1. Assuming your user is in the lib directory, run a single-file simulation with: 

    Usage: ``` ruby run_processor.rb <PATH TO INPUT FILE> ```

    ##### Examples of single-file execution mode:

    ```
    $ ruby run_processor.rb ../spec/input_1.txt 
    Greg: $500
    Hank: error
    Karla: $-93
    $
    ```

    ```
    $ ruby run_processor.rb ../spec/input_2.txt 
    Greg: $500
    $
    ```

    ```
    $ ruby run_processor.rb ../spec/input_3.txt 
    Karla: $-93
    $
    ```

    ```
    $ ruby run_processor.rb ../spec/input_4.txt 
    Hank: error
    $
    ```

    ```
    $ ruby run_processor.rb ../spec/input_5.txt 
    Hank: error
    $
    ```

    ```
    $ ruby run_processor.rb ../spec/input_6.txt 
    Greg: error
    Hank: error
    Karla: error
    $
    ```

    ```
    $ ruby run_processor.rb ../spec/input_7.txt 
    Greg: $500
    Hank: error
    Karla: $-93
    $
    ```

    ```
    $ ruby run_processor.rb ../spec/input_8.txt 
    !@#IKCVXZCD()ANFEKo@N!or321$#: error
    -nmcnxzianieADFSACxczvm: $807
    Greg: error
    Hank: error
    Karla: error
    ben: $0
    bob: $-999
    charlie: $6
    dan: $0
    dee: $7
    frank: $8
    fred: error
    jay: $999
    lkasjadlfkajASJFKDLSJAFKSDAJ: $500
    mac: $5
    $
    ```

    ```
    $ ruby run_processor.rb ../spec/input_9.txt 
    !@#IKCVXZCD()ANFEKo@N!or321$#: error
    -nmcnxzianieADFSACxczvm: $807
    Blanka: $0
    Calvin: $0
    Greg: error
    Hank: error
    He-man: $0
    HeyAbbott: $0
    Hobbes: $0
    Jimbo: $0
    Karla: error
    Liono: $0
    Mumra: $0
    PaulyShore: error
    Punchy: $0
    Sheera: $0
    Storm: $0
    TankAbbott: error
    ben: $0
    bob: $-999
    charlie: $6
    dan: $0
    dee: $7
    frank: $8
    fred: error
    jay: $999
    lkasjadlfkajASJFKDLSJAFKSDAJ: $500
    mac: $5
    $
    ```

1. Assuming your user is in the lib directory, run in interactive mode with: 

    ``` ruby run_processor.rb ```

    Example:

    ```
    $ ruby run_processor.rb 
    Add Greg 4111111111111111 $1000
    Add Karla 5454545454545454 $3000
    Add Hank 1234567890123456 $2000
    Charge Greg $500
    Charge Greg $800
    Charge Karla $7
    Credit Karla $100
    Credit Hank $200

    Greg: $500
    Hank: error
    Karla: $-93
    $
    ```

#### Additional Support

##### Regenerate Documentation

From the root directory you can regenerate the documentation with RDoc from the base directory using:

```
$ ls
Gemfile  Gemfile.lock  lib  README  README.md  spec  SPECS.md
$ rdoc lib 
Parsing sources...
100% [ 5/ 5]  lib/run_processor.rb    

Generating Darkfish format into /home/driver/dev/ruby-luhn-checker-for-credit-card-validation/doc...

  Files:       5

  Classes:     4 (0 undocumented)
  Modules:     0 (0 undocumented)
  Constants:   0 (0 undocumented)
  Attributes:  0 (0 undocumented)
  Methods:    45 (1 undocumented)

  Total:      49 (1 undocumented)
   97.96% documented

  Elapsed: 0.5s

$ 
```

##### How to Enable Debug Mode

Debug mode is supported with the ```-d``` flag placed after the input file argument. Debug mode is not supported from the command line during interactive mode. This is the general command for running in debug enabled during single-file mode: 

##### ``` ruby run_processor.rb <PATH TO INPUT FILE> -d ```

Example:

```
$ ruby run_processor.rb ../spec/input_1.txt -d
Loading File: ../spec/input_1.txt
Process(Add Greg 4111111111111111 $1000)
Add - Creating Account Name(Greg) Card(4111111111111111) Limit($1000)
    Creating Card(4111111111111111)
Process(Add Karla 5454545454545454 $3000)
Add - Creating Account Name(Karla) Card(5454545454545454) Limit($3000)
    Creating Card(5454545454545454)
Process(Add Hank 1234567890123456 $2000)
Add - Creating Account Name(Hank) Card(1234567890123456) Limit($2000)
    Creating Card(1234567890123456)
Process(Charge Greg $500)
Process(Charge Greg $800)
Process(Charge Karla $7)
Process(Credit Karla $100)
Process(Credit Hank $200)


Report: Accounts(3)

Greg: $500
Hank: error
Karla: $-93


Greg: $500
Hank: error
Karla: $-93
$
```

## License

MIT

