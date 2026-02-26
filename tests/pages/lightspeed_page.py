from playwright.sync_api import Page, Locator

from .base_page import BasePage

# MCP_PROMPT: should be a prompt that is expected to return a
# list of available MCP tools when sent to the Lightspeed chat.
MCP_PROMPT = "List the available MCP tools."


# LLM_RESPONSE_TIMEOUT: the maximum time to wait for a response
# from the LLM before timing out.
LLM_RESPONSE_TIMEOUT = 120000 

# DEFAULT_CHAT_ITEM_INDEX: the default index for selecting a
# chat history item.
DEFAULT_CHAT_ITEM_INDEX = 0

class LightspeedPage(BasePage):
    def __init__(self, page: "Page", base_url: "str") -> "None":
        super().__init__(page, base_url)

    def navigate_to_lightspeed(self) -> "None":
        self.navigate("/lightspeed")

    @property
    def homepage_icon(self) -> "Locator":
        """
        locates the Lightspeed floating action button visible on
        the home page.
        """
        return self.page.locator(
            "[data-testid='lightspeed-icon'], "
            "[aria-label*='Lightspeed'], "
            "[aria-label*='lightspeed'], "
            "button[class*='lightspeed'], "
            "button[class*='Lightspeed']"
        ).first

    @property
    def model_selector(self) -> "Locator":
        """
        locates the Model selector dropdown inside the
        Lightspeed chat panel.
        """
        return self.page.locator(
            "select[aria-label*='model'], "
            "[data-testid='model-selector'], "
            "button[aria-label*='model'], "
            "[class*='model-selector']"
        ).first

    @property
    def chat_input(self) -> "Locator":
        """
        locates the Text input / textarea for sending prompts.
        """
        return self.page.locator(
            "textarea[placeholder*='message'], "
            "textarea[aria-label*='message'], "
            "textarea[data-testid*='chat'], "
            "input[placeholder*='message']"
        ).first

    def send_message(self, text: "str") -> "None":
        """
        sends a message to the Lightspeed chat by filling the input
        and pressing Enter.
        """
        self.chat_input.fill(text)
        self.page.keyboard.press("Enter")

    @property
    def response_container(self) -> "Locator":
        """
        locates the Container element that holds
        the AI response messages.
        """
        return self.page.locator(
            "[data-testid='chat-response'], "
            "[class*='chat-message'], "
            "[class*='response-container'], "
            "[aria-live='polite']"
        ).first

    def wait_for_response(self, timeout: "int" = LLM_RESPONSE_TIMEOUT) -> "str":
        """
        waits until a response appears and return its text content.
        """
        self.response_container.wait_for(state="visible", timeout=timeout)
        return self.response_container.inner_text()

    @property
    def history_panel(self) -> "Locator":
        """
        locates the chat history panel that displays previous conversations.
        """
        return self.page.locator(
            "[data-testid='chat-history'], "
            "[aria-label*='history'], "
            "[class*='chat-history']"
        ).first

    def history_item(self, index: "int" = DEFAULT_CHAT_ITEM_INDEX) -> "Locator":
        """
        returns a chat history entry by index (0-based).
        """
        return self.page.locator(
            "[data-testid='history-item'], "
            "[class*='history-item'], "
            "li[class*='history']"
        ).nth(index)
