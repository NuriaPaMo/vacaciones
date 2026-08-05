using Microsoft.Playwright;
using Microsoft.Playwright.NUnit;
using NUnit.Framework;

namespace TimeTracking.E2ETests;

[TestFixture]
public class LoginTests : PageTest
{
    [SetUp]
    public async Task Setup()
    {
        await Page.GotoAsync("http://localhost:5173/login");
    }

    [Test]
    public async Task ShouldLoginSuccessfully()
    {
        // Arrange
        var emailInput = Page.Locator("input[name='email']");
        var passwordInput = Page.Locator("input[type='password']");
        var loginButton = Page.Locator("button[type='submit']");

        // Act
        await emailInput.FillAsync("test.user@example.com");
        await passwordInput.FillAsync("SecurePass123!");
        await loginButton.ClickAsync();

        // Assert
        await Expect(Page).ToHaveURLAsync(new Regex(".*/dashboard"));
        await Expect(Page.Locator("text=Welcome back")).ToBeVisibleAsync();
    }

    [Test]
    public async Task ShouldShowErrorWithInvalidCredentials()
    {
        // Act
        await Page.Locator("input[name='email']").FillAsync("user@example.com");
        await Page.Locator("input[type='password']").FillAsync("WrongPassword");
        await Page.Locator("button[type='submit']").ClickAsync();

        // Assert
        var errorMessage = Page.Locator("[role='alert']");
        await Expect(errorMessage).ToContainTextAsync("Invalid credentials");
    }
}
