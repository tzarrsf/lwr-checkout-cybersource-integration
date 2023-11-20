# lwr-checkout-cybersource-integration

This project contains Apex code relevant to Salesforce Commerce functionality when doing a custom payment integration such as Cybersource. It was donated by one of our brightest and most generous partners who wishes to remain anonymous. Special thanks to that humble and helpful individual for contributing this solution in the spirit of the Code-It-Forward effort!

## ⚠️ Disclaimers

- This code is provided as-is. It's not officially supported by Salesforce, its implementing partners or covered by SLAs.
- API and Apex documentation is not provided with the collection. Please refer to the official documentation.
- The documentation for the majority of the endpoints in this collection can be found in these resources:
     - [CommercePayments Namespace](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_namespace_commercepayments.htm) in the Apex Reference Guide
     - [Payment Gateway Adapters](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_commercepayments_adapter_intro.htm) in the Apex Developers Guide
    - [Use Cases for the CommercePayments Namespace](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_commercepayments_use_cases.htm) in the Apex Developers Guide
    - [Alternative Payment Methods](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_commercepayments_alt_payment_methods.htm) in the Apex Developers Guide
- Being familiar with these resources in the partner community is also helpful in understanding this code:
    - Salesforce Payments Partner Pocket Guide
    - Cybersource Custom Credit Card Form
    - Salesforce Commerce B2B Lightning Web Components Payment Solution
    - Payment Gateway Adapters

## What this code is and isn't

This code is intended to be used for B2B and D2C standalone setups in LWR (Lightning Web Runtime). That isn't to say you can't use it with a Salesforce org containing other commerce products, just that B2B with an LWR checkout model using Cybersource is what's targeted.