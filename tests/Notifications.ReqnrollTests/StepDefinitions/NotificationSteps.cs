using Reqnroll;

namespace Notifications.ReqnrollTests.StepDefinitions;

[Binding]
public class NotificationSteps
{
    [Given(@"the SMTP server is configured and available")]
    public void GivenTheSmtpServerIsConfiguredAndAvailable()
        => throw new NotImplementedException();

    [Given(@"notification templates are seeded for all event types")]
    public void GivenNotificationTemplatesAreSeededForAllEventTypes()
        => throw new NotImplementedException();

    [Given(@"the notification templates are seeded")]
    public void GivenTheNotificationTemplatesAreSeeded()
        => throw new NotImplementedException();

    [Given(@"the critical capacity threshold is (.*)%")]
    public void GivenTheCriticalCapacityThresholdIs(decimal pct)
        => throw new NotImplementedException();

    [Given(@"the warning threshold is (.*)%")]
    public void GivenTheWarningThresholdIs(decimal pct)
        => throw new NotImplementedException();

    [Given(@"employee ""(.*)"" submits a vacation request from ""(.*)"" to ""(.*)""")]
    public void GivenEmployeeSubmitsAVacationRequestFromTo(string email, string start, string end)
        => throw new NotImplementedException();

    [Given(@"the vacation request for ""(.*)"" is finally approved")]
    public void GivenTheVacationRequestForIsFinallyApproved(string email)
        => throw new NotImplementedException();

    [Given(@"the vacation request for ""(.*)"" is rejected with reason ""(.*)""")]
    public void GivenTheVacationRequestForIsRejectedWithReason(string email, string reason)
        => throw new NotImplementedException();

    [Given(@"""(.*)"" cancels an ""(.*)"" vacation request")]
    public void GivenEmployeeCancelsAnVacationRequest(string email, string status)
        => throw new NotImplementedException();

    [Given(@"the SMTP server returns an error on the first (\d+) attempts")]
    public void GivenTheSmtpServerReturnsAnErrorOnTheFirstAttempts(int attempts)
        => throw new NotImplementedException();

    [Given(@"the capacity for ""(.*)"" on ""(.*)"" crosses (.*)%")]
    public void GivenTheCapacityForOnCrosses(string dept, string date, decimal pct)
        => throw new NotImplementedException();

    [Given(@"a capacity alert was already sent for ""(.*)"" on ""(.*)"" at ""(.*)"" level")]
    public void GivenACapacityAlertWasAlreadySentFor(string dept, string date, string level)
        => throw new NotImplementedException();

    [Given(@"an email with action link is sent for request ""(.*)"" to ""(.*)""")]
    public void GivenAnEmailWithActionLinkIsSentForRequestTo(string requestId, string email)
        => throw new NotImplementedException();

    [Given(@"an action link was generated for ""(.*)""")]
    public void GivenAnActionLinkWasGeneratedFor(string email)
        => throw new NotImplementedException();

    [Given(@"an action link was generated (\d+) days ago for ""(.*)""")]
    public void GivenAnActionLinkWasGeneratedDaysAgoFor(int days, string email)
        => throw new NotImplementedException();

    [Given(@"the Teams API returns an error")]
    public void GivenTheTeamsApiReturnsAnError()
        => throw new NotImplementedException();

    [When(@"the ""(.*)"" event is consumed by the notification handler")]
    public void WhenTheEventIsConsumedByTheNotificationHandler(string eventName)
        => throw new NotImplementedException();

    [When(@"the ""(.*)"" event is consumed")]
    public void WhenTheEventIsConsumed(string eventName)
        => throw new NotImplementedException();

    [When(@"a ""(.*)"" event is published at ""(.*)""")]
    public void WhenAnEventIsPublishedAt(string eventName, string dateTime)
        => throw new NotImplementedException();

    [When(@"the notification handler processes the event")]
    public void WhenTheNotificationHandlerProcessesTheEvent()
        => throw new NotImplementedException();

    [When(@"any workflow email notification is sent")]
    public void WhenAnyWorkflowEmailNotificationIsSent()
        => throw new NotImplementedException();

    [When(@"""(.*)"" clicks the action link from the email")]
    public void WhenUserClicksTheActionLinkFromTheEmail(string email)
        => throw new NotImplementedException();

    [When(@"""(.*)"" attempts to use the same link")]
    public void WhenUserAttemptsToUseTheSameLink(string email)
        => throw new NotImplementedException();

    [When(@"""(.*)"" clicks the link")]
    public void WhenUserClicksTheLink(string email)
        => throw new NotImplementedException();

    [When(@"a critical capacity alert notification is processed")]
    public void WhenACriticalCapacityAlertNotificationIsProcessed()
        => throw new NotImplementedException();

    [Then(@"an email notification is sent to project manager ""(.*)""")]
    public void ThenAnEmailNotificationIsSentToProjectManager(string email)
        => throw new NotImplementedException();

    [Then(@"the email contains the request dates, employee name, and an action deep-link")]
    public void ThenTheEmailContainsTheRequestDatesEmployeeNameAndAnActionDeepLink()
        => throw new NotImplementedException();

    [Then(@"an email is sent to ""(.*)"" confirming the approval")]
    public void ThenAnEmailIsSentToConfirmingTheApproval(string email)
        => throw new NotImplementedException();

    [Then(@"the email subject matches the ""(.*)"" template")]
    public void ThenTheEmailSubjectMatchesTheTemplate(string templateName)
        => throw new NotImplementedException();

    [Then(@"an email is sent to ""(.*)"" with the rejection reason ""(.*)""")]
    public void ThenAnEmailIsSentToWithTheRejectionReason(string email, string reason)
        => throw new NotImplementedException();

    [Then(@"the email contains a link back to the application")]
    public void ThenTheEmailContainsALinkBackToTheApplication()
        => throw new NotImplementedException();

    [Then(@"email notifications are sent to both the PM and the DM")]
    public void ThenEmailNotificationsAreSentToBothThePMAndTheDM()
        => throw new NotImplementedException();

    [Then(@"the email indicates the request was previously approved")]
    public void ThenTheEmailIndicatesTheRequestWasPreviouslyApproved()
        => throw new NotImplementedException();

    [Then(@"the corresponding email is sent before ""(.*)""")]
    public void ThenTheCorrespondingEmailIsSentBefore(string dateTime)
        => throw new NotImplementedException();

    [Then(@"the email is retried with exponential backoff")]
    public void ThenTheEmailIsRetriedWithExponentialBackoff()
        => throw new NotImplementedException();

    [Then(@"the email is successfully sent on the (\d+)rd attempt")]
    public void ThenTheEmailIsSuccessfullySentOnTheAttempt(int attemptNumber)
        => throw new NotImplementedException();

    [Then(@"the notification record is marked ""(.*)""")]
    public void ThenTheNotificationRecordIsMarked(string status)
        => throw new NotImplementedException();

    [Then(@"the email body contains Avanade branding elements")]
    public void ThenTheEmailBodyContainsAvanadeBrandingElements()
        => throw new NotImplementedException();

    [Then(@"the email is in HTML format")]
    public void ThenTheEmailIsInHtmlFormat()
        => throw new NotImplementedException();

    [Then(@"an email alert is sent to the department manager ""(.*)""")]
    public void ThenAnEmailAlertIsSentToTheDepartmentManager(string email)
        => throw new NotImplementedException();

    [Then(@"the email contains the affected date ""(.*)"" and capacity percentage (.*)%")]
    public void ThenTheEmailContainsTheAffectedDateAndCapacityPercentage(string date, decimal pct)
        => throw new NotImplementedException();

    [Then(@"an email is sent to ""(.*)"" \(DM\)")]
    public void ThenAnEmailIsSentToDm(string email)
        => throw new NotImplementedException();

    [Then(@"an email is sent to all project managers in ""(.*)""")]
    public void ThenAnEmailIsSentToAllProjectManagersIn(string dept)
        => throw new NotImplementedException();

    [Then(@"a Teams message is sent to each recipient \(BR-100\)")]
    public void ThenATeamsMessageIsSentToEachRecipient()
        => throw new NotImplementedException();

    [Then(@"no duplicate alert email is sent")]
    public void ThenNoDuplicateAlertEmailIsSent()
        => throw new NotImplementedException();

    [Then(@"the ""(.*)"" deduplication record prevents re-alerting")]
    public void ThenTheDeduplicationRecordPreventsReAlerting(string entityName)
        => throw new NotImplementedException();

    [Then(@"the link validates successfully")]
    public void ThenTheLinkValidatesSuccessfully()
        => throw new NotImplementedException();

    [Then(@"the user is redirected to the vacation request detail page for ""(.*)""")]
    public void ThenTheUserIsRedirectedToTheVacationRequestDetailPageFor(string requestId)
        => throw new NotImplementedException();

    [Then(@"the link validation fails with ""(.*)""")]
    public void ThenTheLinkValidationFailsWith(string error)
        => throw new NotImplementedException();

    [Then(@"the link is rejected as expired")]
    public void ThenTheLinkIsRejectedAsExpired()
        => throw new NotImplementedException();

    [Then(@"the user is redirected to the login page with the return URL preserved")]
    public void ThenTheUserIsRedirectedToTheLoginPageWithTheReturnUrlPreserved()
        => throw new NotImplementedException();

    [Then(@"the email notification is still sent successfully")]
    public void ThenTheEmailNotificationIsStillSentSuccessfully()
        => throw new NotImplementedException();

    [Then(@"the Teams failure is logged but does not affect the workflow")]
    public void ThenTheTeamsFailureIsLoggedButDoesNotAffectTheWorkflow()
        => throw new NotImplementedException();
}
