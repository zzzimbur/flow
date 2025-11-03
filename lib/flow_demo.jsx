import React, { useState } from 'react';
import { Home, DollarSign, CheckSquare, Calendar, Settings, Clock, TrendingUp, Plus, Filter, Search, Edit2, Trash2, Crown, Zap, Shield, ChevronRight, X, Copy, BarChart3, PieChart, ArrowUpRight, ArrowDownRight, Target, Repeat } from 'lucide-react';

export default function FlowApp() {
  const [activeTab, setActiveTab] = useState('home');
  const [showAddMenu, setShowAddMenu] = useState(false);
  const [showFullCalendar, setShowFullCalendar] = useState(false);
  const [showTemplates, setShowTemplates] = useState(false);
  const [showFinanceStats, setShowFinanceStats] = useState(false);
  const [showScheduleStats, setShowScheduleStats] = useState(false);

  const HomePage = () => (
    <div className="p-6 pb-24">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-800 mb-1">Доброе утро, Даниил 👋</h1>
        <p className="text-gray-500 text-sm">Среда, 29 октября 2025</p>
      </div>

      {/* Today Summary Card */}
      <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-2xl p-6 mb-6 text-white shadow-lg">
        <div className="flex justify-between items-start mb-4">
          <div>
            <p className="text-blue-100 text-sm mb-1">Сегодня запланировано</p>
            <h2 className="text-4xl font-bold">6.5 ч</h2>
          </div>
          <div className="text-right">
            <p className="text-blue-100 text-sm mb-1">Прогноз дохода</p>
            <h3 className="text-2xl font-bold">₽4,875</h3>
          </div>
        </div>
        <div className="flex justify-between text-sm">
          <div>
            <p className="text-blue-100">Выполнено задач</p>
            <p className="font-semibold text-lg">3 из 5</p>
          </div>
          <div className="text-right">
            <p className="text-blue-100">Ставка</p>
            <p className="font-semibold text-lg">₽750/час</p>
          </div>
        </div>
      </div>

      {/* Monthly Overview */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        <div className="bg-gradient-to-br from-green-50 to-green-100 rounded-xl p-4 border border-green-200">
          <div className="flex items-center gap-2 mb-2">
            <TrendingUp size={20} className="text-green-600" />
            <p className="text-green-700 text-xs font-medium">ДОХОД ЗА МЕСЯЦ</p>
          </div>
          <h3 className="text-2xl font-bold text-green-900">₽124,800</h3>
          <p className="text-green-600 text-xs mt-1">↑ 15% от плана</p>
        </div>
        
        <div className="bg-gradient-to-br from-purple-50 to-purple-100 rounded-xl p-4 border border-purple-200">
          <div className="flex items-center gap-2 mb-2">
            <Clock size={20} className="text-purple-600" />
            <p className="text-purple-700 text-xs font-medium">ОТРАБОТАНО</p>
          </div>
          <h3 className="text-2xl font-bold text-purple-900">164 ч</h3>
          <p className="text-purple-600 text-xs mt-1">Осталось 16 ч</p>
        </div>
      </div>

      {/* Today's Tasks */}
      <div className="mb-6">
        <div className="flex justify-between items-center mb-3">
          <h3 className="text-lg font-bold text-gray-800">Задачи на сегодня</h3>
          <span className="text-xs text-gray-500">3 из 5</span>
        </div>
        
        <div className="space-y-2">
          <TaskItem 
            title="Подготовить отчёт" 
            subtitle="Клиент: Савои"
            color="blue"
            paid={true}
            hours={2}
            done={false}
          />
          <TaskItem 
            title="Созвон с клиентом" 
            subtitle="14:00 - 15:00"
            color="green"
            paid={true}
            hours={1}
            done={true}
          />
          <TaskItem 
            title="Купить продукты" 
            subtitle="Личное"
            color="orange"
            paid={false}
            done={false}
          />
        </div>
      </div>

      {/* Quick Financial Goal */}
      <div className="bg-gray-50 rounded-xl p-4 border border-gray-200">
        <div className="flex justify-between items-center mb-2">
          <p className="text-gray-700 font-medium text-sm">Цель на месяц: ₽150,000</p>
          <p className="text-gray-600 text-xs">83%</p>
        </div>
        <div className="bg-gray-200 rounded-full h-2.5 mb-2 overflow-hidden">
          <div className="bg-gradient-to-r from-blue-500 to-blue-600 h-full rounded-full" style={{width: '83%'}}></div>
        </div>
        <p className="text-gray-600 text-xs">Осталось ₽25,200 • ~34 часа работы</p>
      </div>
    </div>
  );

  const TaskItem = ({ title, subtitle, color, paid, hours, done }) => {
    const colors = {
      blue: 'bg-blue-100 border-blue-300 text-blue-700',
      green: 'bg-green-100 border-green-300 text-green-700',
      orange: 'bg-orange-100 border-orange-300 text-orange-700',
      purple: 'bg-purple-100 border-purple-300 text-purple-700'
    };

    return (
      <div className={`${colors[color]} border rounded-xl p-3 flex items-center gap-3`}>
        <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${done ? 'bg-white border-current' : 'border-current'}`}>
          {done && <div className="w-2.5 h-2.5 rounded-full bg-current"></div>}
        </div>
        <div className="flex-1">
          <p className={`font-medium text-sm ${done ? 'line-through opacity-60' : ''}`}>{title}</p>
          <p className="text-xs opacity-75">{subtitle}</p>
        </div>
        {paid && hours && (
          <div className="text-right">
            <p className="text-xs font-medium">{hours}ч</p>
            <p className="text-xs opacity-75">₽{hours * 750}</p>
          </div>
        )}
      </div>
    );
  };

  const FinancePage = () => (
    <div className="p-6 pb-24">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-gray-800">Финансы</h2>
        <button 
          onClick={() => setShowFinanceStats(!showFinanceStats)}
          className="text-blue-500 text-sm font-medium flex items-center gap-1 hover:text-blue-600 transition-colors"
        >
          <BarChart3 size={18} />
          {showFinanceStats ? 'Скрыть' : 'Статистика'}
        </button>
      </div>

      {showFinanceStats && <FinanceStats />}
      
      {/* Balance Card */}
      <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl p-6 mb-6 text-white shadow-xl">
        <p className="text-gray-400 text-sm mb-2">Баланс</p>
        <h2 className="text-4xl font-bold mb-4">₽24,800</h2>
        <div className="flex justify-between text-sm">
          <div>
            <p className="text-gray-400">Валидесс</p>
            <p className="font-semibold text-lg text-green-400">+₽75,000</p>
          </div>
          <div className="text-right">
            <p className="text-gray-400">Подписки</p>
            <p className="font-semibold text-lg text-red-400">-₽50,200</p>
          </div>
        </div>
      </div>

      {/* Income vs Expenses */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        <div className="bg-green-50 rounded-xl p-4 border border-green-200">
          <p className="text-green-700 text-xs font-medium mb-2">ДОХОД</p>
          <p className="text-2xl font-bold text-green-900">₽124,800</p>
          <p className="text-green-600 text-xs mt-1">164 часа • ₽761/ч</p>
        </div>
        <div className="bg-red-50 rounded-xl p-4 border border-red-200">
          <p className="text-red-700 text-xs font-medium mb-2">РАСХОДЫ</p>
          <p className="text-2xl font-bold text-red-900">₽98,200</p>
          <p className="text-red-600 text-xs mt-1">79% от дохода</p>
        </div>
      </div>

      {/* Expense Categories */}
      <div className="mb-6">
        <h3 className="text-lg font-bold text-gray-800 mb-3">Категории расходов</h3>
        <div className="space-y-2">
          <ExpenseCategory name="Еда" amount="32,000" percent="32" color="blue" budget="40,000" />
          <ExpenseCategory name="Транспорт" amount="18,470" percent="19" color="green" budget="20,000" />
          <ExpenseCategory name="Огнего" amount="20,000" percent="20" color="orange" budget="25,000" />
          <ExpenseCategory name="Развлечения" amount="15,730" percent="16" color="purple" budget="20,000" />
        </div>
      </div>

      {/* Recent Transactions */}
      <div>
        <h3 className="text-lg font-bold text-gray-800 mb-3">Последние операции</h3>
        <div className="space-y-2">
          <Transaction title="Работа: Дизайн лендинга" amount="+12,000" time="Сегодня, 14:30" type="income" />
          <Transaction title="Продукты" amount="-2,450" time="Сегодня, 12:15" type="expense" />
          <Transaction title="Работа: Консультация" amount="+3,750" time="Вчера" type="income" />
        </div>
      </div>
    </div>
  );

  const FinanceStats = () => (
    <div className="bg-white rounded-2xl p-5 mb-6 border border-gray-200 shadow-sm">
      <div className="flex justify-between items-center mb-4">
        <h3 className="font-bold text-gray-800">Финансовая аналитика</h3>
        <select className="text-sm border border-gray-200 rounded-lg px-3 py-1 text-gray-600">
          <option>Этот месяц</option>
          <option>Последние 3 месяца</option>
          <option>Этот год</option>
        </select>
      </div>

      <div className="grid grid-cols-2 gap-3 mb-4">
        <div className="bg-blue-50 rounded-lg p-3">
          <p className="text-xs text-blue-600 mb-1">Средний доход/месяц</p>
          <p className="text-xl font-bold text-blue-900">₽118,400</p>
          <div className="flex items-center gap-1 text-xs text-green-600 mt-1">
            <ArrowUpRight size={12} />
            <span>+12%</span>
          </div>
        </div>
        <div className="bg-purple-50 rounded-lg p-3">
          <p className="text-xs text-purple-600 mb-1">Эффективная ставка</p>
          <p className="text-xl font-bold text-purple-900">₽761/ч</p>
          <div className="flex items-center gap-1 text-xs text-green-600 mt-1">
            <ArrowUpRight size={12} />
            <span>+1.5%</span>
          </div>
        </div>
      </div>

      <div className="bg-gray-50 rounded-lg p-3">
        <p className="text-xs text-gray-600 mb-2">Баланс доходов/расходов</p>
        <div className="flex items-center gap-2">
          <div className="flex-1 bg-green-200 rounded-full h-3" style={{width: '56%'}}></div>
          <div className="flex-1 bg-red-200 rounded-full h-3" style={{width: '44%'}}></div>
        </div>
        <div className="flex justify-between text-xs text-gray-600 mt-1">
          <span>Доход: 56%</span>
          <span>Расход: 44%</span>
        </div>
      </div>
    </div>
  );

  const ExpenseCategory = ({ name, amount, percent, color, budget }) => {
    const colors = {
      blue: 'bg-blue-500',
      green: 'bg-green-500',
      orange: 'bg-orange-500',
      purple: 'bg-purple-500'
    };

    const remaining = parseInt(budget) - parseInt(amount);

    return (
      <div className="bg-white rounded-lg p-3 border border-gray-200">
        <div className="flex justify-between items-center mb-2">
          <p className="font-medium text-gray-800">{name}</p>
          <p className="font-bold text-gray-900">₽{amount}</p>
        </div>
        <div className="bg-gray-100 rounded-full h-2 overflow-hidden mb-1">
          <div className={`${colors[color]} h-full`} style={{width: `${percent}%`}}></div>
        </div>
        <div className="flex justify-between">
          <p className="text-xs text-gray-500">{percent}% от бюджета</p>
          <p className="text-xs text-gray-500">Осталось ₽{remaining.toLocaleString()}</p>
        </div>
      </div>
    );
  };

  const Transaction = ({ title, amount, time, type }) => (
    <div className="bg-white rounded-lg p-3 border border-gray-200 flex items-center justify-between">
      <div>
        <p className="font-medium text-gray-800 text-sm">{title}</p>
        <p className="text-xs text-gray-500">{time}</p>
      </div>
      <p className={`font-bold text-lg ${type === 'income' ? 'text-green-600' : 'text-red-600'}`}>
        {amount}
      </p>
    </div>
  );

  const TasksPage = () => {
    const [filter, setFilter] = useState('today');
    
    const tasks = [
      { id: 1, title: "Подготовить отчёт", client: "Клиент: Савои", hours: 2, rate: 750, deadline: "Сегодня", status: "active", type: "paid", priority: "high", date: "today" },
      { id: 2, title: "Дизайн лендинга", client: "Клиент: TechStart", hours: 4, rate: 800, deadline: "Сегодня", status: "active", type: "paid", priority: "high", date: "today" },
      { id: 3, title: "Созвон с клиентом", client: "14:00 - 15:00", hours: 1, rate: 750, deadline: "Сегодня", status: "done", type: "paid", priority: "medium", date: "today" },
      { id: 4, title: "Купить продукты", client: "Личное", hours: 0, rate: 0, deadline: "Сегодня", status: "active", type: "personal", priority: "low", date: "today" },
      { id: 5, title: "Выставить счета", client: "Административное", hours: 0.5, rate: 0, deadline: "Завтра", status: "active", type: "admin", priority: "medium", date: "tomorrow" },
      { id: 6, title: "Встреча с инвестором", client: "Бизнес", hours: 2, rate: 1000, deadline: "Пятница", status: "active", type: "paid", priority: "high", date: "week" },
    ];

    const filteredTasks = tasks.filter(task => {
      if (filter === 'today') return task.date === 'today';
      if (filter === 'all') return true;
      if (filter === 'paid') return task.type === 'paid';
      if (filter === 'personal') return task.type === 'personal';
      if (filter === 'done') return task.status === 'done';
      return true;
    });

    const todayTasks = tasks.filter(t => t.date === 'today');
    const totalHours = filteredTasks.filter(t => t.type === 'paid' && t.status === 'active').reduce((sum, t) => sum + t.hours, 0);
    const totalEarnings = filteredTasks.filter(t => t.type === 'paid' && t.status === 'active').reduce((sum, t) => sum + (t.hours * t.rate), 0);

    return (
      <div className="p-6 pb-24">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-2xl font-bold text-gray-800">Задачи</h2>
          <button 
            onClick={() => setShowTemplates(true)}
            className="text-blue-500 text-sm font-medium flex items-center gap-1 hover:text-blue-600 transition-colors"
          >
            <Repeat size={18} />
            Шаблоны
          </button>
        </div>
        
        {/* Summary Card */}
        <div className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-2xl p-6 mb-6 text-white shadow-lg">
          <div className="flex justify-between items-start mb-3">
            <div>
              <p className="text-purple-100 text-sm mb-1">Активных задач</p>
              <h2 className="text-4xl font-bold">{tasks.filter(t => t.status === 'active').length}</h2>
            </div>
            <div className="text-right">
              <p className="text-purple-100 text-sm mb-1">Потенциал дохода</p>
              <h3 className="text-2xl font-bold">₽{totalEarnings.toLocaleString()}</h3>
            </div>
          </div>
          <div className="flex justify-between text-sm pt-3 border-t border-purple-400">
            <p className="text-purple-100">Оплачиваемых часов: {totalHours}ч</p>
            <p className="text-purple-100">Выполнено: {tasks.filter(t => t.status === 'done').length}</p>
          </div>
        </div>

        {/* Filters */}
        <div className="flex gap-2 mb-4 overflow-x-auto pb-2">
          <FilterButton label="Сегодня" active={filter === 'today'} onClick={() => setFilter('today')} count={todayTasks.length} />
          <FilterButton label="Все" active={filter === 'all'} onClick={() => setFilter('all')} count={tasks.length} />
          <FilterButton label="Оплачиваемые" active={filter === 'paid'} onClick={() => setFilter('paid')} count={tasks.filter(t => t.type === 'paid').length} />
          <FilterButton label="Личные" active={filter === 'personal'} onClick={() => setFilter('personal')} count={tasks.filter(t => t.type === 'personal').length} />
          <FilterButton label="Выполнено" active={filter === 'done'} onClick={() => setFilter('done')} count={tasks.filter(t => t.status === 'done').length} />
        </div>

        {/* Tasks List */}
        <div className="space-y-3">
          {filteredTasks.map(task => (
            <TaskCard key={task.id} task={task} />
          ))}
        </div>

        {filteredTasks.length === 0 && (
          <div className="text-center py-12">
            <p className="text-gray-400 text-sm">Нет задач в этой категории</p>
          </div>
        )}
      </div>
    );
  };

  const FilterButton = ({ label, active, onClick, count }) => (
    <button 
      onClick={onClick}
      className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
        active 
          ? 'bg-blue-500 text-white shadow-md' 
          : 'bg-white text-gray-600 border border-gray-200 hover:border-blue-300'
      }`}
    >
      {label} ({count})
    </button>
  );

  const TaskCard = ({ task }) => {
    const priorityColors = {
      high: 'border-l-red-500 bg-red-50',
      medium: 'border-l-yellow-500 bg-yellow-50',
      low: 'border-l-green-500 bg-green-50'
    };

    const typeIcons = {
      paid: '💰',
      personal: '🏠',
      admin: '📋'
    };

    return (
      <div className={`bg-white rounded-xl p-4 border-l-4 ${priorityColors[task.priority]} shadow-sm`}>
        <div className="flex items-start justify-between mb-2">
          <div className="flex items-start gap-3 flex-1">
            <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center mt-1 ${
              task.status === 'done' ? 'bg-blue-500 border-blue-500' : 'border-gray-300'
            }`}>
              {task.status === 'done' && <div className="w-2.5 h-2.5 rounded-full bg-white"></div>}
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-1">
                <span className="text-lg">{typeIcons[task.type]}</span>
                <h3 className={`font-semibold text-gray-800 ${task.status === 'done' ? 'line-through opacity-60' : ''}`}>
                  {task.title}
                </h3>
              </div>
              <p className="text-sm text-gray-600 mb-1">{task.client}</p>
              <div className="flex items-center gap-3 text-xs text-gray-500">
                <span>⏰ {task.deadline}</span>
                {task.type === 'paid' && (
                  <span className="text-green-600 font-medium">
                    {task.hours}ч • ₽{(task.hours * task.rate).toLocaleString()}
                  </span>
                )}
              </div>
            </div>
          </div>
          <div className="flex gap-2 ml-2">
            <button className="text-gray-400 hover:text-blue-500 transition-colors">
              <Edit2 size={18} />
            </button>
            <button className="text-gray-400 hover:text-red-500 transition-colors">
              <Trash2 size={18} />
            </button>
          </div>
        </div>
      </div>
    );
  };

  const SchedulePage = () => {
    const [selectedDate, setSelectedDate] = useState(31);
    
    const weekDays = ['М', 'Т', 'С', 'Ч', 'П', 'С', 'В'];
    const dates = [29, 30, 31, 1, 2, 3, 4];
    const workDots = [true, true, true, true, false, false, true];

    const schedule = [
      { id: 1, title: "Дизайн лендинга", client: "TechStart", time: "10:00 - 14:00", hours: 4, rate: 800, color: "blue" },
      { id: 2, title: "Созвон", client: "Савои", time: "14:00 - 15:00", hours: 1, rate: 750, color: "green" },
      { id: 3, title: "Кодинг проекта", client: "StartupX", time: "16:00 - 20:00", hours: 4, rate: 850, color: "purple" },
    ];

    const totalHours = schedule.reduce((sum, s) => sum + s.hours, 0);
    const totalEarnings = schedule.reduce((sum, s) => sum + (s.hours * s.rate), 0);

    return (
      <div className="p-6 pb-24">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-2xl font-bold text-gray-800">График работы</h2>
          <button 
            onClick={() => setShowScheduleStats(!showScheduleStats)}
            className="text-blue-500 text-sm font-medium flex items-center gap-1 hover:text-blue-600 transition-colors"
          >
            <BarChart3 size={18} />
            {showScheduleStats ? 'Скрыть' : 'Статистика'}
          </button>
        </div>

        {showScheduleStats && <ScheduleStats />}
        
        {/* Weekly Summary */}
        <div className="bg-gradient-to-br from-indigo-500 to-indigo-600 rounded-2xl p-6 mb-6 text-white shadow-lg">
          <div className="flex justify-between items-center mb-4">
            <div>
              <p className="text-indigo-100 text-sm mb-1">Неделя 44</p>
              <h2 className="text-3xl font-bold">32 часа</h2>
            </div>
            <div className="text-right">
              <p className="text-indigo-100 text-sm mb-1">Заработано</p>
              <h3 className="text-2xl font-bold">₽24,800</h3>
            </div>
          </div>
          <div className="bg-indigo-400/30 rounded-lg p-3">
            <div className="flex justify-between text-sm">
              <span className="text-indigo-100">Рабочих дней</span>
              <span className="font-semibold">5 из 7</span>
            </div>
          </div>
        </div>

        {/* Calendar Week View */}
        <div className="bg-white rounded-xl p-4 mb-6 shadow-sm border border-gray-200">
          <div className="flex justify-between items-center mb-4">
            <h3 className="font-semibold text-gray-800">Октябрь - Ноябрь 2025</h3>
            <button 
              onClick={() => setShowFullCalendar(true)}
              className="text-blue-500 text-sm font-medium hover:text-blue-600 transition-colors"
            >
              Весь месяц
            </button>
          </div>
          <div className="grid grid-cols-7 gap-2">
            {weekDays.map((day, idx) => (
              <div key={idx} className="text-center">
                <p className="text-xs text-gray-500 mb-2">{day}</p>
                <button
                  onClick={() => setSelectedDate(dates[idx])}
                  className={`w-full aspect-square rounded-lg flex flex-col items-center justify-center text-sm font-medium transition-all ${
                    selectedDate === dates[idx]
                      ? 'bg-blue-500 text-white shadow-md'
                      : 'bg-gray-50 text-gray-800 hover:bg-gray-100'
                  }`}
                >
                  {dates[idx]}
                  {workDots[idx] && (
                    <div className={`w-1 h-1 rounded-full mt-1 ${
                      selectedDate === dates[idx] ? 'bg-white' : 'bg-blue-500'
                    }`}></div>
                  )}
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Today's Schedule */}
        <div>
          <div className="flex justify-between items-center mb-3">
            <h3 className="text-lg font-bold text-gray-800">31 октября</h3>
            <div className="text-right">
              <p className="text-xs text-gray-500">Запланировано</p>
              <p className="font-semibold text-gray-800">{totalHours}ч • ₽{totalEarnings.toLocaleString()}</p>
            </div>
          </div>
          
          <div className="space-y-3">
            {schedule.map(item => (
              <ScheduleCard key={item.id} item={item} />
            ))}
          </div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-3 gap-3 mt-6">
          <StatCard label="Этот месяц" value="164ч" color="blue" />
          <StatCard label="Заработано" value="₽124,800" color="green" />
          <StatCard label="Проектов" value="8" color="purple" />
        </div>
      </div>
    );
  };

  const ScheduleStats = () => (
    <div className="bg-white rounded-2xl p-5 mb-6 border border-gray-200 shadow-sm">
      <div className="flex justify-between items-center mb-4">
        <h3 className="font-bold text-gray-800">Статистика работы</h3>
        <select className="text-sm border border-gray-200 rounded-lg px-3 py-1 text-gray-600">
          <option>Этот месяц</option>
          <option>Последние 3 месяца</option>
          <option>Этот год</option>
        </select>
      </div>

      <div className="grid grid-cols-2 gap-3 mb-4">
        <div className="bg-indigo-50 rounded-lg p-3">
          <p className="text-xs text-indigo-600 mb-1">Всего отработано</p>
          <p className="text-xl font-bold text-indigo-900">164 ч</p>
          <div className="flex items-center gap-1 text-xs text-green-600 mt-1">
            <ArrowUpRight size={12} />
            <span>+8% к прошлому месяцу</span>
          </div>
        </div>
        <div className="bg-green-50 rounded-lg p-3">
          <p className="text-xs text-green-600 mb-1">Самый продуктивный день</p>
          <p className="text-xl font-bold text-green-900">Пт, 25 окт</p>
          <p className="text-xs text-green-600 mt-1">10 часов работы</p>
        </div>
      </div>

      <div className="bg-gray-50 rounded-lg p-3 mb-3">
        <p className="text-xs text-gray-600 mb-2">Распределение по проектам</p>
        <div className="space-y-2">
          <div className="flex items-center gap-2">
            <div className="flex-1 bg-blue-400 rounded-full h-2" style={{width: '40%'}}></div>
            <span className="text-xs text-gray-600">TechStart (40%)</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="flex-1 bg-green-400 rounded-full h-2" style={{width: '30%'}}></div>
            <span className="text-xs text-gray-600">Савои (30%)</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="flex-1 bg-purple-400 rounded-full h-2" style={{width: '30%'}}></div>
            <span className="text-xs text-gray-600">StartupX (30%)</span>
          </div>
        </div>
      </div>

      <div className="bg-amber-50 rounded-lg p-3 border border-amber-200">
        <p className="text-xs text-amber-700 mb-1">💡 Рекомендация</p>
        <p className="text-xs text-amber-800">В среднем вы работаете 6.5 часов в день. Отличный баланс!</p>
      </div>
    </div>
  );

  const ScheduleCard = ({ item }) => {
    const colors = {
      blue: 'bg-blue-100 border-blue-300 text-blue-700',
      green: 'bg-green-100 border-green-300 text-green-700',
      purple: 'bg-purple-100 border-purple-300 text-purple-700',
      orange: 'bg-orange-100 border-orange-300 text-orange-700'
    };

    return (
      <div className={`${colors[item.color]} border rounded-xl p-4`}>
        <div className="flex justify-between items-start mb-2">
          <div className="flex-1">
            <h4 className="font-semibold mb-1">{item.title}</h4>
            <p className="text-sm opacity-75">{item.client}</p>
          </div>
          <div className="text-right">
            <p className="font-bold text-lg">₽{(item.hours * item.rate).toLocaleString()}</p>
            <p className="text-xs opacity-75">{item.hours}ч × ₽{item.rate}</p>
          </div>
        </div>
        <div className="flex items-center gap-2 text-sm">
          <Clock size={14} />
          <span>{item.time}</span>
        </div>
      </div>
    );
  };

  const StatCard = ({ label, value, color }) => {
    const colors = {
      blue: 'bg-blue-50 text-blue-700',
      green: 'bg-green-50 text-green-700',
      purple: 'bg-purple-50 text-purple-700'
    };

    return (
      <div className={`${colors[color]} rounded-lg p-3 text-center`}>
        <p className="text-xs opacity-75 mb-1">{label}</p>
        <p className="font-bold text-sm">{value}</p>
      </div>
    );
  };

  const SettingsPage = () => {
    const [isPremium, setIsPremium] = useState(false);
    const [notifications, setNotifications] = useState(true);
    const [darkMode, setDarkMode] = useState(false);
    const [sync, setSync] = useState(true);
    const [showProfileEdit, setShowProfileEdit] = useState(false);

    return (
      <div className="p-6 pb-24">
        <h2 className="text-2xl font-bold text-gray-800 mb-6">Настройки</h2>
        
        {/* Premium Upsell */}
        {!isPremium && (
          <div className="bg-gradient-to-br from-amber-400 via-orange-400 to-red-400 rounded-2xl p-6 mb-6 text-white shadow-xl">
            <div className="flex items-start gap-4 mb-4">
              <div className="bg-white/20 backdrop-blur-sm rounded-full p-3">
                <Crown size={28} />
              </div>
              <div className="flex-1">
                <h3 className="text-xl font-bold mb-1">Flow Premium</h3>
                <p className="text-sm text-white/90">Разблокируйте все возможности</p>
              </div>
            </div>
            
            <div className="space-y-2 mb-4">
              <PremiumFeature icon={<Zap size={16} />} text="Неограниченные проекты и клиенты" />
              <PremiumFeature icon={<TrendingUp size={16} />} text="Расширенная аналитика и прогнозы" />
              <PremiumFeature icon={<Shield size={16} />} text="Экспорт данных в PDF/Excel" />
              <PremiumFeature icon={<Clock size={16} />} text="Автоматический расчёт налогов" />
            </div>

            <button 
              onClick={() => {
                setIsPremium(true);
                alert('🎉 Добро пожаловать в Premium! 7 дней бесплатно.');
              }}
              className="w-full bg-white text-orange-500 font-bold py-3 rounded-xl shadow-lg hover:bg-gray-50 transition-all active:scale-95"
            >
              Начать бесплатный пробный период
            </button>
            <p className="text-center text-xs text-white/80 mt-2">7 дней бесплатно, затем ₽299/мес</p>
          </div>
        )}

        {/* Pricing Plans */}
        <div className="mb-6">
          <h3 className="font-semibold text-gray-800 mb-3">Тарифные планы</h3>
          <div className="space-y-3">
            <PricingCard 
              name="Бесплатный"
              price="₽0"
              period="навсегда"
              features={["До 3 активных проектов", "Базовая статистика", "Ручной ввод данных"]}
              current={!isPremium}
              onSelect={() => setIsPremium(false)}
            />
            <PricingCard 
              name="Premium"
              price="₽299"
              period="в месяц"
              features={["Неограниченные проекты", "Расширенная аналитика", "Экспорт данных", "Приоритетная поддержка"]}
              current={isPremium}
              highlight={true}
              onSelect={() => setIsPremium(true)}
            />
            <PricingCard 
              name="Business"
              price="₽599"
              period="в месяц"
              features={["Всё из Premium", "Командная работа (до 5 человек)", "Интеграция с банками", "AI-помощник"]}
              current={false}
              onSelect={() => alert('Business план будет доступен скоро!')}
            />
          </div>
        </div>

        {/* Settings Sections */}
        <div className="space-y-4">
          <SettingsSection title="Аккаунт">
            <SettingsItem 
              icon="👤" 
              label="Профиль" 
              value="Даниил" 
              onClick={() => setShowProfileEdit(!showProfileEdit)}
            />
            <SettingsItem 
              icon="📧" 
              label="Email" 
              value="daniil@flow.app" 
              onClick={() => alert('Редактирование email')}
            />
            <SettingsItem 
              icon="🔔" 
              label="Уведомления" 
              toggle={true}
              toggleValue={notifications}
              onToggle={() => setNotifications(!notifications)}
            />
          </SettingsSection>

          <SettingsSection title="Финансы">
            <SettingsItem 
              icon="💰" 
              label="Основная ставка" 
              value="₽750/час" 
              onClick={() => alert('Изменить ставку')}
            />
            <SettingsItem 
              icon="💳" 
              label="Валюта" 
              value="RUB (₽)" 
              onClick={() => alert('Выбрать валюту')}
            />
            <SettingsItem 
              icon="📊" 
              label="Налоговая ставка" 
              value="6%" 
              onClick={() => alert('Изменить налоговую ставку')}
            />
          </SettingsSection>

          <SettingsSection title="Приложение">
            <SettingsItem 
              icon="🌙" 
              label="Тёмная тема" 
              toggle={true}
              toggleValue={darkMode}
              onToggle={() => setDarkMode(!darkMode)}
            />
            <SettingsItem 
              icon="🌍" 
              label="Язык" 
              value="Русский" 
              onClick={() => alert('Выбор языка')}
            />
            <SettingsItem 
              icon="🔄" 
              label="Синхронизация" 
              toggle={true}
              toggleValue={sync}
              onToggle={() => setSync(!sync)}
            />
          </SettingsSection>

          <SettingsSection title="Поддержка">
            <SettingsItem 
              icon="❓" 
              label="Помощь и FAQ" 
              onClick={() => alert('Открыть справку')}
            />
            <SettingsItem 
              icon="⭐" 
              label="Оценить приложение" 
              onClick={() => alert('Спасибо за оценку! ⭐⭐⭐⭐⭐')}
            />
            <SettingsItem 
              icon="📱" 
              label="Поделиться с друзьями" 
              onClick={() => alert('Поделиться Flow')}
            />
          </SettingsSection>
        </div>

        {/* Danger Zone */}
        <div className="mt-6 pt-6 border-t border-gray-200">
          <button 
            onClick={() => {
              if (confirm('Вы уверены, что хотите выйти?')) {
                alert('Вы вышли из аккаунта');
              }
            }}
            className="text-red-500 text-sm font-medium hover:text-red-600 transition-colors"
          >
            Выйти из аккаунта
          </button>
        </div>
      </div>
    );
  };

  const PremiumFeature = ({ icon, text }) => (
    <div className="flex items-center gap-2 text-sm">
      <div className="text-white/90">{icon}</div>
      <span className="text-white/95">{text}</span>
    </div>
  );

  const PricingCard = ({ name, price, period, features, current, highlight, onSelect }) => (
    <div className={`rounded-xl p-4 border-2 ${
      highlight 
        ? 'border-orange-400 bg-gradient-to-br from-orange-50 to-red-50' 
        : current 
          ? 'border-blue-400 bg-blue-50' 
          : 'border-gray-200 bg-white'
    }`}>
      <div className="flex justify-between items-start mb-3">
        <div>
          <h4 className="font-bold text-gray-800">{name}</h4>
          <div className="flex items-baseline gap-1 mt-1">
            <span className="text-2xl font-bold text-gray-900">{price}</span>
            <span className="text-sm text-gray-500">/{period}</span>
          </div>
        </div>
        {current && (
          <span className="bg-blue-500 text-white text-xs font-medium px-2 py-1 rounded-full">
            Текущий
          </span>
        )}
        {highlight && (
          <span className="bg-orange-500 text-white text-xs font-medium px-2 py-1 rounded-full">
            Популярный
          </span>
        )}
      </div>
      
      <ul className="space-y-2 mb-3">
        {features.map((feature, idx) => (
          <li key={idx} className="flex items-start gap-2 text-sm text-gray-700">
            <span className="text-green-500 mt-0.5">✓</span>
            <span>{feature}</span>
          </li>
        ))}
      </ul>

      {!current && (
        <button 
          onClick={onSelect}
          className={`w-full py-2 rounded-lg font-medium text-sm transition-all active:scale-95 ${
            highlight
              ? 'bg-orange-500 text-white hover:bg-orange-600'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          }`}
        >
          Выбрать план
        </button>
      )}
    </div>
  );

  const SettingsSection = ({ title, children }) => (
    <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
      <h4 className="font-semibold text-gray-700 text-sm px-4 py-3 bg-gray-50 border-b border-gray-200">
        {title}
      </h4>
      <div className="divide-y divide-gray-100">
        {children}
      </div>
    </div>
  );

  const SettingsItem = ({ icon, label, value, toggle, toggleValue, onToggle, onClick }) => (
    <button 
      onClick={toggle ? onToggle : onClick}
      className="w-full flex items-center justify-between px-4 py-3 hover:bg-gray-50 transition-colors text-left"
    >
      <div className="flex items-center gap-3">
        <span className="text-xl">{icon}</span>
        <span className="text-gray-700 text-sm">{label}</span>
      </div>
      <div className="flex items-center gap-2">
        {value && <span className="text-gray-500 text-sm">{value}</span>}
        {toggle && (
          <div 
            className={`w-11 h-6 rounded-full relative transition-colors ${
              toggleValue ? 'bg-blue-500' : 'bg-gray-300'
            }`}
          >
            <div className={`w-5 h-5 bg-white rounded-full absolute top-0.5 shadow-sm transition-transform ${
              toggleValue ? 'right-0.5' : 'left-0.5'
            }`}></div>
          </div>
        )}
        {!toggle && <ChevronRight size={18} className="text-gray-400" />}
      </div>
    </button>
  );

  // Modals
  const FullCalendarModal = () => {
    if (!showFullCalendar) return null;

    const monthDays = Array.from({ length: 31 }, (_, i) => i + 1);
    const workDays = [1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 15, 16, 17, 18, 19, 22, 23, 24, 25, 26, 29, 30, 31];

    return (
      <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => setShowFullCalendar(false)}>
        <div className="bg-white rounded-2xl max-w-md w-full max-h-[80vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
          <div className="sticky top-0 bg-white border-b border-gray-200 p-4 flex justify-between items-center">
            <h3 className="text-lg font-bold text-gray-800">Октябрь 2025</h3>
            <button onClick={() => setShowFullCalendar(false)} className="text-gray-400 hover:text-gray-600 transition-colors">
              <X size={24} />
            </button>
          </div>
          
          <div className="p-4">
            <div className="grid grid-cols-7 gap-2 mb-2">
              {['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'].map((day, idx) => (
                <div key={idx} className="text-center text-xs font-medium text-gray-500">
                  {day}
                </div>
              ))}
            </div>
            
            <div className="grid grid-cols-7 gap-2">
              {monthDays.map((day) => (
                <button
                  key={day}
                  onClick={() => alert(`Выбрана дата: ${day} октября`)}
                  className={`aspect-square rounded-lg flex flex-col items-center justify-center text-sm font-medium transition-all active:scale-95 ${
                    workDays.includes(day)
                      ? 'bg-blue-500 text-white hover:bg-blue-600'
                      : 'bg-gray-50 text-gray-400 hover:bg-gray-100'
                  }`}
                >
                  {day}
                  {workDays.includes(day) && (
                    <div className="w-1 h-1 rounded-full bg-white mt-1"></div>
                  )}
                </button>
              ))}
            </div>
            
            <div className="mt-4 bg-blue-50 rounded-lg p-3 border border-blue-200">
              <p className="text-sm text-blue-800">
                <span className="font-semibold">23 рабочих дня</span> • 164 часа • ₽124,800
              </p>
            </div>
          </div>
        </div>
      </div>
    );
  };

  const TemplatesModal = () => {
    if (!showTemplates) return null;

    const templates = [
      { id: 1, name: "Встреча с клиентом", type: "task", hours: 1, rate: 750, icon: "💼" },
      { id: 2, name: "Дизайн лендинга", type: "task", hours: 4, rate: 800, icon: "🎨" },
      { id: 3, name: "Код-ревью", type: "task", hours: 2, rate: 850, icon: "💻" },
      { id: 4, name: "Рабочий день (8 часов)", type: "schedule", hours: 8, rate: 750, icon: "📅" },
      { id: 5, name: "Половина дня (4 часа)", type: "schedule", hours: 4, rate: 750, icon: "⏰" },
      { id: 6, name: "Консультация", type: "task", hours: 1.5, rate: 1000, icon: "🎓" },
    ];

    return (
      <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => setShowTemplates(false)}>
        <div className="bg-white rounded-2xl max-w-md w-full max-h-[80vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
          <div className="sticky top-0 bg-white border-b border-gray-200 p-4 flex justify-between items-center">
            <h3 className="text-lg font-bold text-gray-800">Шаблоны</h3>
            <button onClick={() => setShowTemplates(false)} className="text-gray-400 hover:text-gray-600 transition-colors">
              <X size={24} />
            </button>
          </div>
          
          <div className="p-4">
            <p className="text-sm text-gray-600 mb-4">
              Быстро создавайте задачи и записи в графике на основе готовых шаблонов
            </p>
            
            <div className="space-y-2">
              {templates.map(template => (
                <button
                  key={template.id}
                  onClick={() => alert(`Создана задача из шаблона: ${template.name}`)}
                  className="w-full bg-white border border-gray-200 rounded-xl p-3 hover:border-blue-300 hover:bg-blue-50 transition-all active:scale-98"
                >
                  <div className="flex items-center gap-3">
                    <span className="text-2xl">{template.icon}</span>
                    <div className="flex-1 text-left">
                      <h4 className="font-semibold text-gray-800 text-sm">{template.name}</h4>
                      <p className="text-xs text-gray-500">
                        {template.hours}ч • ₽{(template.hours * template.rate).toLocaleString()}
                      </p>
                    </div>
                    <Plus size={20} className="text-blue-500" />
                  </div>
                </button>
              ))}
            </div>
            
            <button 
              onClick={() => alert('Создание нового шаблона')}
              className="w-full mt-4 bg-gray-100 text-gray-700 py-3 rounded-xl font-medium hover:bg-gray-200 transition-all active:scale-98 flex items-center justify-center gap-2"
            >
              <Plus size={20} />
              Создать новый шаблон
            </button>
          </div>
        </div>
      </div>
    );
  };

  const AddMenu = () => {
    if (!showAddMenu) return null;

    return (
      <div className="fixed inset-0 bg-black/50 z-50 flex items-end justify-center" onClick={() => setShowAddMenu(false)}>
        <div className="bg-white rounded-t-3xl w-full max-w-md p-6 pb-8" onClick={(e) => e.stopPropagation()}>
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-xl font-bold text-gray-800">Добавить</h3>
            <button onClick={() => setShowAddMenu(false)} className="text-gray-400 hover:text-gray-600 transition-colors">
              <X size={24} />
            </button>
          </div>
          
          <div className="space-y-3">
            <AddMenuItem 
              icon={<CheckSquare size={24} />} 
              label="Новая задача" 
              description="Создать задачу с дедлайном"
              color="blue"
              onClick={() => {
                setShowAddMenu(false);
                alert('Создание новой задачи');
              }}
            />
            <AddMenuItem 
              icon={<Calendar size={24} />} 
              label="Запись в графике" 
              description="Запланировать рабочее время"
              color="purple"
              onClick={() => {
                setShowAddMenu(false);
                alert('Добавление записи в график');
              }}
            />
            <AddMenuItem 
              icon={<DollarSign size={24} />} 
              label="Доход/Расход" 
              description="Добавить финансовую операцию"
              color="green"
              onClick={() => {
                setShowAddMenu(false);
                alert('Добавление финансовой операции');
              }}
            />
            <AddMenuItem 
              icon={<Target size={24} />} 
              label="Цель" 
              description="Установить финансовую цель"
              color="orange"
              onClick={() => {
                setShowAddMenu(false);
                alert('Создание новой цели');
              }}
            />
            <AddMenuItem 
              icon={<Repeat size={24} />} 
              label="Из шаблона" 
              description="Использовать готовый шаблон"
              color="gray"
              onClick={() => {
                setShowAddMenu(false);
                setShowTemplates(true);
              }}
            />
          </div>
        </div>
      </div>
    );
  };

  const AddMenuItem = ({ icon, label, description, color, onClick }) => {
    const colors = {
      blue: 'bg-blue-100 text-blue-600',
      purple: 'bg-purple-100 text-purple-600',
      green: 'bg-green-100 text-green-600',
      orange: 'bg-orange-100 text-orange-600',
      gray: 'bg-gray-100 text-gray-600'
    };

    return (
      <button 
        onClick={onClick}
        className="w-full bg-white border border-gray-200 rounded-xl p-4 hover:border-blue-300 hover:bg-blue-50 transition-all active:scale-98 flex items-center gap-4"
      >
        <div className={`${colors[color]} rounded-full p-3`}>
          {icon}
        </div>
        <div className="flex-1 text-left">
          <h4 className="font-semibold text-gray-800">{label}</h4>
          <p className="text-sm text-gray-500">{description}</p>
        </div>
        <ChevronRight size={20} className="text-gray-400" />
      </button>
    );
  };

  const renderContent = () => {
    switch(activeTab) {
      case 'home': return <HomePage />;
      case 'finance': return <FinancePage />;
      case 'tasks': return <TasksPage />;
      case 'schedule': return <SchedulePage />;
      case 'settings': return <SettingsPage />;
      default: return <HomePage />;
    }
  };

  return (
    <div className="max-w-md mx-auto bg-gray-50 min-h-screen relative">
      {/* Status Bar */}
      <div className="bg-white px-6 py-3 flex justify-between items-center text-xs text-gray-600">
        <span>1:40</span>
        <span>Flow</span>
        <span>⚡ 85%</span>
      </div>

      {/* Content */}
      <div className="overflow-y-auto" style={{height: 'calc(100vh - 120px)'}}>
        {renderContent()}
      </div>

      {/* Bottom Navigation */}
      <div className="absolute bottom-0 left-0 right-0 bg-white border-t border-gray-200 px-6 py-3 flex justify-around items-center">
        <NavItem icon={<Home size={24} />} label="Главная" active={activeTab === 'home'} onClick={() => setActiveTab('home')} />
        <NavItem icon={<DollarSign size={24} />} label="Финансы" active={activeTab === 'finance'} onClick={() => setActiveTab('finance')} />
        <NavItem icon={<CheckSquare size={24} />} label="Задачи" active={activeTab === 'tasks'} onClick={() => setActiveTab('tasks')} />
        <NavItem icon={<Calendar size={24} />} label="График" active={activeTab === 'schedule'} onClick={() => setActiveTab('schedule')} />
        <NavItem icon={<Settings size={24} />} label="Еще" active={activeTab === 'settings'} onClick={() => setActiveTab('settings')} />
      </div>

      {/* Floating Action Button */}
      <button 
        onClick={() => setShowAddMenu(true)}
        className="absolute bottom-20 right-6 bg-blue-500 text-white rounded-full p-4 shadow-lg hover:bg-blue-600 transition-all hover:scale-110 active:scale-95"
      >
        <Plus size={28} />
      </button>

      {/* Modals */}
      <AddMenu />
      <FullCalendarModal />
      <TemplatesModal />
    </div>
  );
}

function NavItem({ icon, label, active, onClick }) {
  return (
    <button 
      onClick={onClick}
      className={`flex flex-col items-center gap-1 transition-colors ${active ? 'text-blue-500' : 'text-gray-400'}`}
    >
      {icon}
      <span className="text-xs font-medium">{label}</span>
    </button>
  );
}