# Overview

In NYS, Epi Contacts is deployed by its original name, Share My Contacts.

## SMS Trigger Workflow

The SMS is a message whose template is stored in CommCare as a conditional alert, which contains a link to the 
running Epi Contacts application.

The logic to determine if a patient should receive an SMS message is relatively complex.
If a patient case meets preconditions, as defined in 
`EpiContacts.CommcareSmsTrigger.case_meets_preconditions?/2` and conditions as defined in
`EpiContacts.CommcareSmsTrigger.case_meets_conditions?/3`, then the application will send a request to 
CommCare to send the SMS to the patient.

<pre>
<code class="mermaid">
sequenceDiagram;
    CommCare->>Epi Contacts: case forwarded;
    alt case has not been sent SMS before;
        Epi Contacts->>Epi Contacts: check preconditions;
        Epi Contacts->>Epi Contacts: check conditions;
        alt if conditions met;
            Epi Contacts-->>CommCare: send SMS;
        end;
    end;
</code>
</pre>

There are 3 precondition scenarios to be aware of: `pre_ci`, `pre_ci_minor` and `post_ci`.

`pre_ci` and `pre_ci_minor` are for when a patient case has been forwarded by CommCare upon create, or very 
shortly after. We differentiate between adults and minors to avoid sending SMS messages to minors.

`post_ci` is for when a Contact Tracer ("CT") or Case Investigator ("CI") pushes a button from within 
CommCare to send the patient an SMS. This still passes through Epi Contacts so the trigger 
logic can live in a single place.

## Contact Elicitation Workflow

Upon clicking the link in the SMS, a patient is presened with the Epi Contacts application.

<pre>
<code class="mermaid">
sequenceDiagram;
    Patient Case->>Epi Contacts: validate token;
    alt token valid;
        Epi Contacts->>CommCare: get patient case;
        CommCare-->>Epi Contacts: patient case;
        alt case is minor;
            Epi Contacts-->>Patient Case: present minor page;
        else;
            Epi Contacts-->>Patient Case: confirm identity;
            Patient Case->>Patient Case: register contacts;
            Patient Case->>Epi Contacts: submit contacts;
            Epi Contacts->>CommCare: submit contacts;
        end;
    else token invalid;
        Epi Contacts-->>Patient Case: invalid/expired token;
    end;
</code>
</pre>

## Performance

## Releases

Please see the [Release log](https://ratiopbc.slab.com/public/posts/6o7z66ec).
