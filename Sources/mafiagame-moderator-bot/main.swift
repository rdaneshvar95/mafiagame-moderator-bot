import Foundation
import TelegramBotSDK

let token = readToken(from: "MAFIAGAME_MODERATOR_BOT_TOKEN")
let adminId = 60493668
let bot = TelegramBot(token: token)
let router = Router(bot: bot)

func assignRoles() {
    guard var roles = configurations[players.count]?.shuffled() else {
        fatalError("no configuration found for \(players.count) players")
    }

    players.forEach { player in
        var player = player
        player.role = roles.removeFirst()
        players.update(with: player)
    }
}

var gameState: GameState = .preparing

enum GameState {
    case preparing
    case started
}

enum PlayerState {
    case new
    case play
}

enum Role: String {
    case citizen
    case detective
    case doctor
    case diehard
    case professional
    case mafia
    case mayor
    case godfather
    case lecter
    case psychiatrist
}

struct Player: Equatable, Hashable {
    let id: Int64
    let name: String
    var role: Role?
    var isAlive = true
    var isRevealed = false
    var state: PlayerState = .new

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

var players = Set<Player>()

let configurations: [Int: [Role]] = [
    12: [.citizen, .citizen, .doctor, .detective, .professional, .diehard, .mayor, .psychiatrist, .mafia, .mafia, .godfather, .lecter]
]

router["start"] = { context in
    guard let from = context.message?.from, gameState == .preparing else { return false }

    let player = Player(id: from.id, name: from.firstName, isAlive: true, isRevealed: false)
    players.update(with: player)

    let button1 = KeyboardButton(text: "🙋 Yeah")
    let button2 = KeyboardButton(text: "🙅 Nope")
    let markup = ReplyKeyboardMarkup(keyboard: [[button1, button2]])
    markup.oneTimeKeyboard = true
    context.respondAsync("Are you in?", replyMarkup: .replyKeyboardMarkup(markup))

    return true
}

router["🙋 Yeah"] = { context in
    context.respondAsync("Welcome", replyMarkup: .replyKeyboardRemove(ReplyKeyboardRemove(removeKeyboard: true)))
    return true
}

router["🙅 Nope"] = { context in
    guard let from = context.message?.from, let player = players.first(where: { $0.id == from.id }) else { return false }

    players.remove(player)

    context.respondAsync("Bye", replyMarkup: .replyKeyboardRemove(ReplyKeyboardRemove(removeKeyboard: true)))
    return true
}

router["begin"] = { context in
    guard let from = context.message?.from, from.id == adminId  else { return false }

    gameState = .started
    assignRoles()

    players.forEach({ bot.sendMessageAsync(chatId: .chat($0.id), text: $0.role!.rawValue) })

    bot.sendMessageSync(chatId: .channel("@mafiagame_narrator"), text: "DAY 1")
    return true
}

while let update = bot.nextUpdateSync() {
    try router.process(update: update)
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
