# Методические указания к практической работе №1
## Тема: Проектирование архитектуры программных модулей с применением паттернов GoF и нотации UML

* **Дисциплина:** МДК.01.01 «Разработка, поддержка и тестирование программных модулей»  
* **Специальность:** 09.02.07 «Информационные системы и программирование»  
* **Группа:** 2ИП-16-25  
* **Язык реализации:** C# (.NET 8 / .NET Core) или Python 3.10+  
* **Форма отчетности:** Отчет в электронном виде с приложением исходного кода проекта.

---

## 1. Теоретические основы проектирования ПО

### 1.1. Модульность и принципы слабого зацепления (Loose Coupling)
Программный модуль — это логически обособленный блок исходного кода (класс, библиотека, пакет), решающий конкретную функциональную задачу и взаимодействующий с остальной системой через строго определенный публичный интерфейс (API).

При проектировании архитектуры модулей ключевыми инженерными целями являются:
* **High Cohesion (Высокая связность внутри модуля):** модуль решает строго одну задачу предметной области (соответствует принципу Single Responsibility Principle — SRP).
* **Loose Coupling (Слабое зацепление между модулями):** модули изолированы друг от друга; изменение внутренней реализации одного модуля не ломает код других компонентов. Взаимодействие строится через абстрактные интерфейсы, а не конкретные реализации.

---

### 1.2. Нотация UML-диаграммы классов (Class Diagram)
Диаграмма классов описывает статическую структуру системы, типы данных, атрибуты, сигнатуры методов и характер связей между сущностями.

#### Обозначение элементов класса:
```
┌──────────────────────────────────────┐
│             <<interface>>            │
│               IPayment               │
├──────────────────────────────────────┤
│ - _apiKey: string                    │
├──────────────────────────────────────┤
│ + Pay(amount: decimal): bool         │
│ # ValidateAccount(id: int): bool     │
└──────────────────────────────────────┘
```
* **Модификаторы видимости:**
  * `+` — **Public** (публичный член, доступен из любого места кода).
  * `-` — **Private** (приватный член, доступен только внутри данного класса).
  * `#` — **Protected** (защищенный, доступен только внутри класса и его потомков).
  * `~` — **Internal / Package-private** (доступен в пределах текущей сборки).

#### Типы отношений между классами:
1. **Ассоциация (`───>`):** смысловая связь между объектами (класс A использует или ссылается на класс B).
2. **Агрегация (`◇───`):** отношение «часть-целое», где составная часть может существовать независимо от контейнера (например: `Компьютерный класс ◇─── ПК`).
3. **Композиция (`◆───`):** жесткое владение, при котором жизненный цикл части неразрывно связан с целым (например: `Заказ ◆─── Позиция заказа`). Если удалить заказ, его строки уничтожаются.
4. **Обобщение / Наследование (`───▷`):** связь между родительским и дочерним классом (`Person ───▷ Student`).
5. **Реализация (`- - -▷`):** имплементация интерфейса классом (`IPayment - - -▷ SbpPayment`).

---

### 1.3. Архитектурные паттерны проектирования (GoF — Gang of Four)

#### 1. Паттерн «Singleton» (Одиночка) — Порождающий паттерн
* **Назначение:** Гарантирует наличие в приложении ровно одного экземпляра класса и предоставляет глобальную потокобезопасную точку доступа к нему.
* **Применение:** Подключение к СУБД, служба логирования (Logger), диспетчер конфигурации (`AppConfig`).
* **Каноническая потокобезопасная реализация на C#:**
```csharp
public sealed class DatabaseConnection
{
    private static readonly Lazy<DatabaseConnection> _instance = 
        new Lazy<DatabaseConnection>(() => new DatabaseConnection());

    public string ConnectionString { get; private set; }

    // Приватный конструктор запрещает вызов через 'new' из внешнего кода
    private DatabaseConnection()
    {
        ConnectionString = "Server=db.prod.local;Database=BankDB;User Id=app;Password=secret;";
    }

    // Глобальная точка доступа
    public static DatabaseConnection Instance => _instance.Value;

    public void ExecuteQuery(string sql)
    {
        Console.WriteLine($"[DB] Выполнение запроса: {sql}");
    }
}
```

#### 2. Паттерн «Strategy» (Стратегия) — Поведенческий паттерн
* **Назначение:** Инкапсулирует семейство взаимозаменяемых алгоритмов в отдельные классы, реализующие общий интерфейс. Позволяет изменять поведение объекта во время выполнения (Runtime) без изменения клиентского кода и без каскадных конструкций `if-else` / `switch`.
* **Применение:** Способы оплаты (Карта, СБП, Криптовалюта), алгоритмы расчета налогов/скидок, алгоритмы сортировки, маршруты доставки.
* **Реализация на C#:**
```csharp
// 1. Общий интерфейс алгоритмов
public interface IPaymentStrategy
{
    bool ProcessPayment(decimal amount);
}

// 2. Конкретные стратегии
public class CardPaymentStrategy : IPaymentStrategy
{
    private readonly string _cardNumber;
    public CardPaymentStrategy(string cardNumber) => _cardNumber = cardNumber;

    public bool ProcessPayment(decimal amount)
    {
        Console.WriteLine($"Оплата {amount:C} с банковской карты {_cardNumber} успешна.");
        return true;
    }
}

public class SbpPaymentStrategy : IPaymentStrategy
{
    private readonly string _phoneNumber;
    public SbpPaymentStrategy(string phoneNumber) => _phoneNumber = phoneNumber;

    public bool ProcessPayment(decimal amount)
    {
        Console.WriteLine($"Генерация QR-кода СБП для номера {_phoneNumber} на сумму {amount:C}.");
        return true;
    }
}

// 3. Контекст, использующий стратегию
public class OrderCheckout
{
    private IPaymentStrategy _paymentStrategy;

    public void SetPaymentStrategy(IPaymentStrategy strategy)
    {
        _paymentStrategy = strategy;
    }

    public void CompleteOrder(decimal totalAmount)
    {
        if (_paymentStrategy == null)
            throw new InvalidOperationException("Не выбран способ оплаты!");

        _paymentStrategy.ProcessPayment(totalAmount);
    }
}
```

#### 3. Паттерн «Factory Method» (Фабричный метод) — Порождающий паттерн
* **Назначение:** Делегирует создание объектов специализированным классам-создателям, избавляя вызывающий код от привязки к конкретным именам классов.
* **Применение:** Генераторы отчетов (PDF, Excel, JSON), отправка уведомлений (Email, SMS, Push).
* **Реализация на C#:**
```csharp
// Продукт
public interface INotification
{
    void Send(string recipient, string message);
}

public class EmailNotification : INotification
{
    public void Send(string recipient, string message) => 
        Console.WriteLine($"[Email -> {recipient}]: {message}");
}

public class SmsNotification : INotification
{
    public void Send(string recipient, string message) => 
        Console.WriteLine($"[SMS -> {recipient}]: {message}");
}

// Фабрика
public abstract class NotificationCreator
{
    public abstract INotification CreateNotification();

    public void NotifyUser(string recipient, string message)
    {
        INotification notification = CreateNotification();
        notification.Send(recipient, message);
    }
}

public class EmailNotificationCreator : NotificationCreator
{
    public override INotification CreateNotification() => new EmailNotification();
}

public class SmsNotificationCreator : NotificationCreator
{
    public override INotification CreateNotification() => new SmsNotification();
}
```

---

## 2. Пошаговое руководство к выполнению работы

### Этап 1. Анализ технического задания и декомпозиция
1. Ознакомьтесь с вариантом задания (выдается по номеру в журнале).
2. Выделите предметные сущности, их атрибуты и операции.
3. Определите, какой паттерн проектирования (`Singleton`, `Strategy`, `Factory Method`, `Observer`) решает задачу наиболее оптимально с соблюдением принципов SOLID.

### Этап 2. Проектирование UML-диаграммы
1. В инструменте визуального моделирования (PlantUML, draw.io, Mermaid или StarUML) постройте диаграмму классов.
2. Обязательно отобразите:
   * Интерфейсы с префиксом `I` (`IStrategy`, `INotification`);
   * Конкретные классы-реализации;
   * Корректные стрелки отношений (реализация, композиция, агрегация, зависимость);
   * Типы данных полей и возвращаемых значений методов.

### Этап 3. Программная реализация модуля
1. Создайте в IDE (Visual Studio / JetBrains Rider / VS Code) консольный проект.
2. Реализуйте интерфейсы и классы строго по спроектированной UML-диаграмме.
3. В функции `Main()` напишите демонстрационный сценарий:
   * Продемонстрируйте динамическую смену поведения (для Strategy);
   * Продемонстрируйте факт создания единственного экземпляра при многократном обращении (для Singleton: `ReferenceEquals(a, b) == true`);
   * Продемонстрируйте создание объектов через фабрику (для Factory Method).
4. Предусмотрите базовую валидацию входных данных и обработку исключений (`ArgumentNullException`, `InvalidOperationException`).

---

## 3. Требования к оформлению отчета

Отчет сдается в электронном виде (Markdown / DOCX / PDF) и содержит:
1. **Титульную информацию:** наименование дисциплины, номер и тема практической работы, группа, ФИО студента, вариант задания.
2. **Текст технического задания:** краткая формулировка задачи варианта.
3. **UML-диаграмму классов:** качественный экспорт схемы в формате PNG/SVG.
4. **Листинг программного кода:** форматированный код классов с комментариями к ключевым методам и конструкции паттерна.
5. **Скриншоты выполнения программы:** подтверждение корректной работы сценариев в терминале/консоли.
6. **Выводы по работе:** обоснование преимуществ примененного паттерна перед монолитным решением «в лоб».

---

## 4. Контрольные вопросы для защиты работы

1. Какую фундаментальную проблему решает паттерн *Strategy* и почему замена логики через `switch/case` считается плохой практикой (нарушением принципа Open-Closed)?
2. Почему в многопоточных приложениях наивная реализация паттерна *Singleton* (`if (instance == null) instance = new ...`) приводит к состоянию гонки (Race Condition)?
3. В чем отличие композиции от агрегации на UML-диаграмме и в коде на уровне жизненного цикла объектов?
4. В каких ситуациях фабричный метод предпочтительнее прямого создания объекта через оператор `new`?
5. Что означает принцип инверсии зависимостей (Dependency Inversion Principle — D из SOLID) и как интерфейсы помогают его соблюдать?
