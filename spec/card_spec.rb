require "card"
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
test_object         = Card.new(test_credit_card_map["American Express"], 0.0)

describe Card do

  describe "perform luhn 10 check" do
    context "test that mock credit card numbers are supported" do
      it "by iterating over the map" do

        test_credit_card_map.each do |key,val|
            
            test_object       = Card.new(val, 0.0)
            test_object.dlg("Testing Key(#{key}) Value(#{val})", 6)
            expect(test_object.perform_luhn_check()).to be true
            expect(test_object.is_valid()).to be true
            expect(test_object.is_invalid()).to be false
        end

        test_object.dlg("Passed Positive Luhn Checks", 5) 

      end
    end
  end

  describe "perform negative luhn 10 checks" do
    context "test that BAD credit card numbers are supported" do
      it "by iterating over the map" do

        test_bad_cards.each do |key,val|
            
            test_object       = Card.new(val, false)
            test_object.dlg("Testing Key(#{key}) Value(#{val})", 6)
            expect(test_object.perform_luhn_check()).to be false
            expect(test_object.is_valid()).to be false
            expect(test_object.is_invalid()).to be true
        end

        test_object.dlg("Passed Negative Luhn Checks", 5) 

      end
    end
  end

  describe "valid starting limit" do
    context "test that credit card limits are supported" do
      it "by verifying the limit" do

        card_number         = test_credit_card_map["Visa"].to_s
        limit               = 200.0
        test_object         = Card.new(card_number, limit)
        expect(test_object.get_limit().to_i).to eq(limit.to_i)

        test_object.dlg("Card Starting Limits Passed", 5) 

      end
    end
  end

  describe "valid starting balance" do
    context "test that credit card balance are supported" do
      it "by verifying the balance" do

        card_number         = test_credit_card_map["Visa"].to_s
        limit               = 300.0
        test_object         = Card.new(card_number, limit)
        expect(test_object.get_balance().to_i).to eq(0.to_i)

        test_object.dlg("Card Starting Balances Passed", 5) 

      end
    end
  end

  describe "charges work" do
    context "test that credit card charges increase the balance" do
      it "by verifying the balance and limit" do

        card_number         = test_credit_card_map["Visa"].to_s
        limit               = 400.0
        test_object         = Card.new(card_number, limit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(0.to_i)

        current_balance     = test_object.get_balance()
        current_charge      = 100
        test_object._charge_helper(current_charge)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance + current_charge)

        current_balance     = test_object.get_balance()
        current_charge      = 200
        test_object._charge_helper(current_charge)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance + current_charge)

        test_object.dlg("Card Charges Passed", 5) 

      end
    end
  end

  describe "charges work up to the limit" do
    context "test that credit card charges increase the balance to the limit" do
      it "by verifying the balance and limit" do

        card_number         = test_credit_card_map["Visa"].to_s
        limit               = 400.0
        test_object         = Card.new(card_number, limit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(0.to_i)

        current_balance     = test_object.get_balance()
        current_charge      = 100
        test_object._charge_helper(current_charge)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance + current_charge)

        current_balance     = test_object.get_balance()
        current_charge      = 200
        test_object._charge_helper(current_charge)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance + current_charge)

        # This will overcharge the card
        current_balance     = test_object.get_balance()
        current_charge      = 200
        test_object._charge_helper(current_charge)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance)

        test_object.dlg("Card Charges Passed - Hit Limit", 5) 

      end
    end
  end

  describe "credits work" do
    context "test that credit card credits decrease the balance" do
      it "by verifying the balance and limit" do

        card_number         = test_credit_card_map["Visa"].to_s
        limit               = 400.0
        test_object         = Card.new(card_number, limit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(0.to_i)

        current_balance     = test_object.get_balance()
        current_credit      = 100
        test_object._credit_helper(current_credit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance - current_credit)

        current_balance     = test_object.get_balance()
        current_credit      = 202
        test_object._credit_helper(current_credit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance - current_credit)

        current_balance     = test_object.get_balance()
        current_credit      = 301
        test_object._credit_helper(current_credit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance - current_credit)

        current_balance     = test_object.get_balance()
        current_credit      = 410
        test_object._credit_helper(current_credit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance - current_credit)

        current_balance     = test_object.get_balance()
        current_credit      = 550
        test_object._credit_helper(current_credit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance - current_credit)

        current_balance     = test_object.get_balance()
        current_credit      = 654
        test_object._credit_helper(current_credit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance - current_credit)

        test_object.dlg("Card Credits Passed", 5) 

      end
    end
  end

  describe "credits and charges work" do
    context "test that credit card credits and charges modify the balance" do
      it "by verifying the balance and limit" do

        card_number         = test_credit_card_map["Visa"].to_s
        limit               = 400.0
        test_object         = Card.new(card_number, limit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(0.to_i)

        current_balance     = test_object.get_balance()
        current_credit      = 100
        test_object._credit_helper(current_credit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance - current_credit)

        current_balance     = test_object.get_balance()
        current_credit      = 202
        test_object._credit_helper(current_credit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance - current_credit)

        # Over the card limit
        current_balance     = test_object.get_balance()
        current_charge      = test_object.get_limit() - test_object.get_balance() + 1
        test_object.dlg("B(#{current_balance}) C(#{current_charge})", 6)
        test_object._charge_helper(current_charge)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance)

        current_balance     = test_object.get_balance()
        current_credit      = 301
        test_object._credit_helper(current_credit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance - current_credit)
        
        current_balance     = test_object.get_balance()
        current_charge      = 102
        test_object._charge_helper(current_charge)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance + current_charge)

        current_balance     = test_object.get_balance()
        current_credit      = 410
        test_object._credit_helper(current_credit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance - current_credit)

        current_balance     = test_object.get_balance()
        current_charge      = 601
        test_object._charge_helper(current_charge)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance + current_charge)

        current_balance     = test_object.get_balance()
        current_credit      = 550
        test_object._credit_helper(current_credit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance - current_credit)

        current_balance     = test_object.get_balance()
        current_charge      = 701
        test_object._charge_helper(current_charge)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance + current_charge)

        current_balance     = test_object.get_balance()
        current_credit      = 654
        test_object._credit_helper(current_credit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance - current_credit)

        # Over the card limit
        current_balance     = test_object.get_balance()
        current_charge      = 1701
        test_object._charge_helper(current_charge)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance)

        # At the card limit
        current_balance     = test_object.get_balance()
        current_charge      = (-1 * test_object.get_balance()) + test_object.get_limit()
        test_object.dlg("B(#{current_balance}) C(#{current_charge})", 6)
        test_object._charge_helper(current_charge)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(test_object.get_limit())

        current_balance     = test_object.get_balance()
        current_credit      = 858
        test_object._credit_helper(current_credit)
        expect(test_object.get_limit()).to eq(limit.to_i)
        expect(test_object.get_balance()).to eq(current_balance - current_credit)

        test_object.dlg("Simulated Card Credits and Charges Passed Balance(#{test_object.get_balance()})", 5) 

      end
    end
  end

end

