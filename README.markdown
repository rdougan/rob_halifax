## rob_halifax

This is a simple application written using Rails 3 which will scrape the [Halifax Online Banking](https://www.halifax-online.co.uk/personal/logon/login.jsp) and [Northern Bank](http://northernbank.co.uk/) websites and return your account details and latest transactions in a JSON format. It uses a mobile user agent to keep loading times down (as they both *finally* have a mobile site).

It uses [Mechanize](http://mechanize.rubyforge.org/) and [Nokogiri](http://nokogiri.org/), both of which are fantastic.

**Please, please, please don't be silly and put this online somewhere with your details without using an extra authentication layer.**

### Setup

I'm using this as a [Heroku](http://www.heroku.com/) application, so I store the login details as environment variables. You can find out how to use them on Heroku over on the [Heroku Help Center](http://devcenter.heroku.com/articles/config-vars).

For local development, you can simply set the environment variables in your `.bash_profile` file:

	export HALIFAX_USERNAME="myusername"
	export HALIFAX_PASSWORD="mypassword"
	export HALIFAX_SECRET="mylowercasesecret"

For simple authentication, I also check for a `UUID` environment variable. It can be comma seperated.

Then fire up the Rails server and it will give your a JSON response:

```javascript
{
    "accounts": [
        {
            "figures": [
                {
                    "Balance": 5046.0
                },
                {
                    "Money available": 5024.3
                },
                {
                    "Overdraft": 50.0
                }
            ],
            "information": "11-88-99, 012345",
            "name": "Current Account",
            "transactions": [
                {
                    "balance": 5046.0,
                    "date": "2011-12-01",
                    "is_credit": false,
                    "name": "STUPID BANK FEES",
                    "value": -50.0
                },
                ...
            ]
        },
        {
            "figures": [
                {
                    "Available credit": 9100.0
                },
                {
                    "Credit limit": 9100.0
                }
            ],
            "information": "1234 5678 9101 1121",
            "name": "ONE CARD",
            "transactions": []
        }
    ],
    "success": true
}
```

### Warning

I don't advice you to put this on a web server without adding another form of authentication on top of it.

**Use this at your own risk. I will not be held responsible.**