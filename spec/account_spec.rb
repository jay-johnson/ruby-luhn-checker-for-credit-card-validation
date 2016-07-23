require "card"
require "account"
require "logging"

# Cards ripped from paypal: http://www.paypalobjects.com/en_US/vhelp/paypalmanager_help/credit_card_numbers.htm
test_credit_card_map = {
    "American Express" => "378282246310005",
    "American Express 2" => "371449635398431",
    "American Express Corporate" => "378734493671000",
    "Australian BankCard" => "5610591081018250",
    "Diners Club" => "30569309025904",
    "Diners Club 2" => "38520000023237",
    "Discover" => "6011111111111117",
    "Discover 2" => "6011000990139424",
    "JCB" => "3530111333300000",
    "JCB 2" => "3566002020360505",
    "MasterCard" => "5555555555554444",
    "MasterCard 2" => "5105105105105100",
    "Visa" => "4111111111111111",
    "Visa 2" => "4012888888881881",
    "Visa 3" => "4222222222222",
}

test_bad_cards      = {
    "Bad American Express" => "---",
    "Bad American Express 2" => '018u321#*@()!*#()@!)$*!@)$!',
    "Bad American Express Corporate" => "@!#N!KVcd-vi0 13j4219 3j2019 i",
    "Bad Australian BankCard" => "21382190cmsdae@!~# N@!K+#)!+_!@)+! ",
    "Bad Diners Club" => 'jsakr0121@#@!MR\#@0c90832131',
    "Bad Diners Club 2" => '0-1321SA@!#@!jdvmkdsmoaok',
    "Bad Discover" => "-12321123213",
    "Bad Discover 2" => "",
    "Bad JCB" => "a",
    "Bad JCB 2" => "3566002020360505123219cv9",
    "Bad MasterCard" => "5533445515150944",
    "Bad MasterCard 2" => "81390281309218093481",
    "Bad Visa" => "490218390218911111",
    "Bad Visa 2" => "4012!88888881881",
    "Bad Visa 3" => "22222222222",
    "Bad Visa 4" => "ASDFASCXCXZCXZ",
    "Bad Visa 5" => "ASDFASCXCXZCXZCnmnvxczo0",
    "Bad Visa 6" => "Cnmnvxczo021xcvjioueSAF",
    "Bad Visa 7" => "   -1          ",
    "Bad Visa 8" => "    -2         ",
    "Bad Visa 9" => "     -3        ",
    "Bad Visa A" => "      -4       ",
    "Bad Visa B" => "       -5      ",
}

test_debug          = false

describe Account do

  describe "account creation" do
    context "test that an account can be created" do
      it "by verifying the class" do
            
        new_account_name    = "User"
        test_object         = Account.new(new_account_name)
        expect(test_object.get_name()).to eq(new_account_name)

        test_object.dlg("Account Creation Supported", 5) 

      end
    end
  end

  describe "starting account has no default source" do
    context "test that a starting account has no default source" do
      it "by verifying the source" do
            
        new_account_name    = "User"
        test_object         = Account.new(new_account_name)
        
        expect(test_object.get_default_source().get_status()).to eq(Card.new("2000000000000000", 0).get_status())
        expect(test_object.get_default_source().get_limit()).to  eq(Card.new("2000000000000000", 0).get_limit())
        expect(test_object.is_valid?()).to                       eq(false)

        test_object.dlg("Account Creation Supported", 5) 

      end
    end
  end

  describe "account credit card" do
    context "test accounts support adding a credit card" do
      it "by adding a valid card" do
            
        new_account_name    = "User"
        limit               = 555
        limit_str           = "$" + limit.to_s
        test_object         = Account.new(new_account_name)

        test_object.add(test_credit_card_map["MasterCard"], limit_str)
        expect(test_object.get_default_source().get_status()).to eq(Card.new(test_credit_card_map["MasterCard"], limit).get_status())
        expect(test_object.get_default_source().get_limit()).to  eq(Card.new(test_credit_card_map["MasterCard"], limit).get_limit())
        expect(test_object.get_default_source().get_balance()).to  eq(0)

        test_object.dlg("Account Creation Supported", 5) 

      end
    end
  end

  describe "account credit cards that do not exist" do
    context "test accounts do not have any credit cards" do
      it "by trying to charge and credit a non-existent card" do
            
        new_account_name    = "User"
        limit               = 555
        limit_str           = "$" + limit.to_s
        current_charge      = "$300"
        current_credit      = "$100"

        test_object         = Account.new(new_account_name, test_debug)
        charge_amount       = test_object.convert_amount_to_float(current_charge)
        credit_amount       = test_object.convert_amount_to_float(current_credit)
        
        # Unable to charge or credit without a card
        expect(test_object.charge(test_credit_card_map["MasterCard"], limit_str)).to eq(1)
        expect(test_object.credit(test_credit_card_map["MasterCard"], limit_str)).to eq(1)

        # Add a card
        test_object.add(test_credit_card_map["MasterCard"], limit_str)

        # Able to charge or credit without a card
        expect(test_object.charge(current_charge)).to eq(0)
        expect(test_object.credit(current_credit)).to eq(0)

        expect(test_object.get_default_source().get_status()).to    eq(Card.new(test_credit_card_map["MasterCard"], limit).get_status())
        expect(test_object.get_default_source().get_limit()).to     eq(Card.new(test_credit_card_map["MasterCard"], limit).get_limit())
        expect(test_object.get_default_source().get_balance()).to   eq(charge_amount.to_i - credit_amount.to_i)

        test_object.dlg("Account Creation Supported", 5) 

      end
    end
  end

  describe "account invalid credit card" do
    context "test accounts reject adding a non-Luhn 10 credit card" do
      it "by trying to add an invalid card" do
            
        new_account_name    = "User"
        limit               = 555
        limit_str           = "$" + limit.to_s
        test_object         = Account.new(new_account_name)

        test_object.add(test_bad_cards["Bad MasterCard"], limit_str)
        expect(test_object.get_default_source().get_status()).to eq(Card.new("2000000000000000", 0).get_status())
        expect(test_object.get_default_source().get_limit()).to  eq(Card.new("2000000000000000", 0).get_limit())
        expect(test_object.is_valid?()).to                       eq(false)

        test_object.dlg("Account Creation Supported", 5) 

      end
    end
  end

  describe "account error checking credit cards" do
    context "test accounts can handle error checks" do
      it "by trying to add and test adding real and non-existent cards" do
            
        new_account_name    = "User"
        limit               = 555
        limit_str           = "$" + limit.to_s
        current_charge      = "$300"
        current_credit      = "$100"

        test_object         = Account.new(new_account_name, test_debug)
        charge_amount       = test_object.convert_amount_to_float(current_charge)
        credit_amount       = test_object.convert_amount_to_float(current_credit)
        
        # Unable to charge or credit without a card
        expect(test_object.charge(test_credit_card_map["MasterCard"], limit_str)).to eq(1)
        expect(test_object.credit(test_credit_card_map["MasterCard"], limit_str)).to eq(1)

        # Add a bad card
        test_object.add(test_bad_cards["Bad MasterCard"], limit_str)
        expect(test_object.get_default_source().get_status()).to eq(Card.new("2000000000000000", 0).get_status())
        expect(test_object.get_default_source().get_limit()).to  eq(Card.new("2000000000000000", 0).get_limit())
        expect(test_object.is_valid?()).to                       eq(false)

        # Add a card
        test_object.add(test_credit_card_map["MasterCard"], limit_str)

        # Able to charge or credit without a card
        expect(test_object.charge(current_charge)).to eq(0)
        expect(test_object.credit(current_credit)).to eq(0)

        expect(test_object.get_default_source().get_status()).to    eq(Card.new(test_credit_card_map["MasterCard"], limit).get_status())
        expect(test_object.get_default_source().get_limit()).to     eq(Card.new(test_credit_card_map["MasterCard"], limit).get_limit())
        expect(test_object.get_default_source().get_balance()).to   eq(charge_amount.to_i - credit_amount.to_i)

        test_object.dlg("Account Creation Supported", 5) 

      end
    end
  end
end

