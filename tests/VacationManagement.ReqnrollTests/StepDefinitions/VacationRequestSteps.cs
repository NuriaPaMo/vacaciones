using Reqnroll;

namespace VacationManagement.ReqnrollTests.StepDefinitions;

[Binding]
public class VacationRequestSteps
{
    // ─── Background ───────────────────────────────────────────────────────────

    [Given(@"I am authenticated as employee ""(.*)"" with role ""(.*)""")]
    public void GivenIAmAuthenticatedAsEmployeeWithRole(string email, string role)
        => throw new NotImplementedException();

    [Given(@"the employee has a vacation balance of (\d+) available days")]
    public void GivenTheEmployeeHasAVacationBalanceOf(int days)
        => throw new NotImplementedException();

    [Given(@"today is ""(.*)""")]
    public void GivenTodayIs(string date)
        => throw new NotImplementedException();

    // ─── Submit ───────────────────────────────────────────────────────────────

    [When(@"I submit a vacation request from ""(.*)"" to ""(.*)""")]
    public void WhenISubmitAVacationRequestFromTo(string startDate, string endDate)
        => throw new NotImplementedException();

    [When(@"I submit a vacation request from ""(.*)"" to ""(.*)"" with notes ""(.*)""")]
    public void WhenISubmitAVacationRequestFromToWithNotes(string startDate, string endDate, string notes)
        => throw new NotImplementedException();

    [When(@"I submit a vacation request starting on ""(.*)""")]
    public void WhenISubmitAVacationRequestStartingOn(string startDate)
        => throw new NotImplementedException();

    [Then(@"a vacation request is created with status ""(.*)""")]
    public void ThenAVacationRequestIsCreatedWithStatus(string status)
        => throw new NotImplementedException();

    [Then(@"the total business days calculated is (\d+)")]
    public void ThenTheTotalBusinessDaysCalculatedIs(int days)
        => throw new NotImplementedException();

    [Then(@"a confirmation response contains the request id")]
    public void ThenAConfirmationResponseContainsTheRequestId()
        => throw new NotImplementedException();

    [Then(@"the weekend days ""(.*)"" and ""(.*)"" are excluded from the count")]
    public void ThenTheWeekendDaysAreExcludedFromTheCount(string saturday, string sunday)
        => throw new NotImplementedException();

    [Then(@"the submission fails with error code ""(.*)""")]
    public void ThenTheSubmissionFailsWithErrorCode(string errorCode)
        => throw new NotImplementedException();

    [Then(@"the submission result is ""(.*)""")]
    public void ThenTheSubmissionResultIs(string result)
        => throw new NotImplementedException();

    [Then(@"the error response includes remaining balance of (\d+) days")]
    public void ThenTheErrorResponseIncludesRemainingBalanceOfDays(int days)
        => throw new NotImplementedException();

    [Then(@"the notes ""(.*)"" are persisted with the request")]
    public void ThenTheNotesArePersistedWithTheRequest(string notes)
        => throw new NotImplementedException();

    [Then(@"no vacation request is created")]
    public void ThenNoVacationRequestIsCreated()
        => throw new NotImplementedException();

    // ─── Calendar UI ──────────────────────────────────────────────────────────

    [Given(@"I am on the new vacation request form")]
    public void GivenIAmOnTheNewVacationRequestForm()
        => throw new NotImplementedException();

    [When(@"I select ""(.*)"" as the start date on the calendar")]
    public void WhenISelectAsTheStartDateOnTheCalendar(string date)
        => throw new NotImplementedException();

    [When(@"I select ""(.*)"" as the end date on the calendar")]
    public void WhenISelectAsTheEndDateOnTheCalendar(string date)
        => throw new NotImplementedException();

    [Then(@"the date range ""(.*)"" to ""(.*)"" is highlighted on the calendar")]
    public void ThenTheDateRangeIsHighlightedOnTheCalendar(string startDate, string endDate)
        => throw new NotImplementedException();

    [Then(@"the label shows ""(.*) business days""")]
    public void ThenTheLabelShowsBusinessDays(string count)
        => throw new NotImplementedException();

    // ─── Overlap ──────────────────────────────────────────────────────────────

    [Given(@"I have an existing ""(.*)"" vacation request from ""(.*)"" to ""(.*)""")]
    public void GivenIHaveAnExistingVacationRequestFromTo(string status, string startDate, string endDate)
        => throw new NotImplementedException();

    // ─── Track ────────────────────────────────────────────────────────────────

    [Given(@"the employee has the following vacation requests:")]
    public void GivenTheEmployeeHasTheFollowingVacationRequests(DataTable table)
        => throw new NotImplementedException();

    [Given(@"I have a vacation request with the following status history:")]
    public void GivenIHaveAVacationRequestWithTheFollowingStatusHistory(DataTable table)
        => throw new NotImplementedException();

    [Given(@"the employee has no vacation requests")]
    public void GivenTheEmployeeHasNoVacationRequests()
        => throw new NotImplementedException();

    [Given(@"I have a vacation request with status ""(.*)""")]
    public void GivenIHaveAVacationRequestWithStatus(string status)
        => throw new NotImplementedException();

    [When(@"I navigate to ""(.*)""")]
    public void WhenINavigateTo(string path)
        => throw new NotImplementedException();

    [When(@"I filter by status ""(.*)""")]
    public void WhenIFilterByStatus(string status)
        => throw new NotImplementedException();

    [When(@"I click on that vacation request to view details")]
    public void WhenIClickOnThatVacationRequestToViewDetails()
        => throw new NotImplementedException();

    [Then(@"I see a list of (\d+) vacation requests")]
    public void ThenISeeAListOfVacationRequests(int count)
        => throw new NotImplementedException();

    [Then(@"each request shows dates, total days, status, and submission date")]
    public void ThenEachRequestShowsDatesTotalDaysStatusAndSubmissionDate()
        => throw new NotImplementedException();

    [Then(@"the first request in the list is the most recently submitted")]
    public void ThenTheFirstRequestInTheListIsTheMostRecentlySubmitted()
        => throw new NotImplementedException();

    [Then(@"the list is sorted by submission date descending")]
    public void ThenTheListIsSortedBySubmissionDateDescending()
        => throw new NotImplementedException();

    [Then(@"I see a timeline showing (\d+) status transitions")]
    public void ThenISeeATimelineShowingStatusTransitions(int count)
        => throw new NotImplementedException();

    [Then(@"the rejection entry shows the reason ""(.*)""")]
    public void ThenTheRejectionEntryShowsTheReason(string reason)
        => throw new NotImplementedException();

    [Then(@"only the request with status ""(.*)"" is shown")]
    public void ThenOnlyTheRequestWithStatusIsShown(string status)
        => throw new NotImplementedException();

    [Then(@"requests with other statuses are hidden")]
    public void ThenRequestsWithOtherStatusesAreHidden()
        => throw new NotImplementedException();

    [Then(@"I see the empty state message ""(.*)""")]
    public void ThenISeeTheEmptyStateMessage(string message)
        => throw new NotImplementedException();

    [Then(@"the status badge for that request displays colour ""(.*)""")]
    public void ThenTheStatusBadgeForThatRequestDisplaysColour(string colour)
        => throw new NotImplementedException();

    // ─── Cancel ───────────────────────────────────────────────────────────────

    [Given(@"I have a ""(.*)"" vacation request from ""(.*)"" to ""(.*)""")]
    public void GivenIHaveAVacationRequestFromTo(string status, string startDate, string endDate)
        => throw new NotImplementedException();

    [When(@"I cancel that vacation request")]
    public void WhenICancelThatVacationRequest()
        => throw new NotImplementedException();

    [When(@"I click ""Cancel"" on that vacation request")]
    public void WhenIClickCancelOnThatVacationRequest()
        => throw new NotImplementedException();

    [When(@"I confirm the cancellation")]
    public void WhenIConfirmTheCancellation()
        => throw new NotImplementedException();

    [When(@"I click ""Keep Request"" to dismiss")]
    public void WhenIClickKeepRequestToDismiss()
        => throw new NotImplementedException();

    [When(@"I view that vacation request")]
    public void WhenIViewThatVacationRequest()
        => throw new NotImplementedException();

    [When(@"I rapidly double-click ""Cancel"" on that vacation request")]
    public void WhenIRapidlyDoubleClickCancelOnThatVacationRequest()
        => throw new NotImplementedException();

    [When(@"I attempt to cancel that request as ""(.*)""")]
    public void WhenIAttemptToCancelThatRequestAs(string email)
        => throw new NotImplementedException();

    [Then(@"the request status changes to ""(.*)""")]
    public void ThenTheRequestStatusChangesTo(string status)
        => throw new NotImplementedException();

    [Then(@"a status transition record is created with actor ""(.*)"" and from status ""(.*)""")]
    public void ThenAStatusTransitionRecordIsCreatedWithActorAndFromStatus(string actor, string fromStatus)
        => throw new NotImplementedException();

    [Then(@"a confirmation dialog is displayed asking to confirm cancellation")]
    public void ThenAConfirmationDialogIsDisplayedAskingToConfirmCancellation()
        => throw new NotImplementedException();

    [Then(@"a ""(.*)"" event is published to the Service Bus")]
    public void ThenAnEventIsPublishedToTheServiceBus(string eventName)
        => throw new NotImplementedException();

    [Then(@"the event contains the previous status ""(.*)""")]
    public void ThenTheEventContainsThePreviousStatus(string status)
        => throw new NotImplementedException();

    [Then(@"no ""Cancel"" action button is visible")]
    public void ThenNoCancelActionButtonIsVisible()
        => throw new NotImplementedException();

    [Then(@"the request status remains ""(.*)""")]
    public void ThenTheRequestStatusRemains(string status)
        => throw new NotImplementedException();

    [Then(@"no status transition record is created")]
    public void ThenNoStatusTransitionRecordIsCreated()
        => throw new NotImplementedException();

    [Then(@"the cancellation is rejected with HTTP 403 ""(.*)""")]
    public void ThenTheCancellationIsRejectedWithHTTP403(string errorCode)
        => throw new NotImplementedException();

    [Then(@"only one status transition is created")]
    public void ThenOnlyOneStatusTransitionIsCreated()
        => throw new NotImplementedException();

    [Then(@"the final status is ""(.*)""")]
    public void ThenTheFinalStatusIs(string status)
        => throw new NotImplementedException();
}
