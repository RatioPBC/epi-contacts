# Epi Contacts

Epi Contacts is a software application designed to elicit contact
information from positive COVID-19 cases to help case investigation and
contact tracing teams operate more efficiently. Epi Contacts receives
positive COVID-19 case information, triggers SMS messages to be sent to
eligible cases, and presents cases with a mobile-friendly web form that
provides isolation instructions and enables submission of close contact
information. Data received from cases is automatically and securely
uploaded to the corresponding case record in the case management system.
Event data -- including both user and API interactions -- are logged
to enable downstream analytics around system utilization.

Epi Contacts was designed for and is deployed in production for the New
York State Department of Health integrated with NY-CDCMS, a contact
tracing system built on [CommCare](https://dimagi.com/commcare/) from
[Dimagi](https://dimagi.com/).

The development of Epi Contacts is sponsored by [Resolve to Save Lives,
an initiative of Vital Strategies](https://resolvetosavelives.org/).

## Transition

This application was originally called `Share My Contacts` and that's
how it's currently deployed in New York. It was renamed to `Epi Contacts`
rebranding but the code lagged until open sourcing in June 2021.

There are references to `Share My Contacts` in content and metrics
to maintain backwards compaibility, for now.

# Usage

The source code is published here to inspire others to do similar work,
but it is not expected that the code be reusable in any other settings
than those for which it was written. Anyone interested in studying the
code should be able to download it and run the test suite.

The software is being actively developed on MacOS and Linux.

The application currently depends on [Oban
Pro](https://getoban.pro), which is a commercial plugin to the queue manager
[Oban](https://hexdocs.pm/oban),
and a (very affordable) license is required to complete the
installation and run the test suite. We are working on making Oban Pro
optional in the future.

# Contributing

Epi Contacts is not open-contribution. It was built for one user, and
it's being maintained for that user only. Also, in order to keep Epi
Contacts in the public domain and ensure that the code does not become
contaminated with proprietary or licensed content, the project does not
accept pull requests or patches from unknown persons.

## Copyright and license

Copyright (c) 2021 [Ratio PBC, Inc](https://ratiopbc.com).
The code is made available under the Apache License, Version 2.0.
See also [LICENSE](LICENSE).
