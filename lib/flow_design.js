import React, { useState } from 'react';
import { Calendar, Plus, TrendingUp, CheckCircle, Clock, DollarSign, Settings, Home, X, ChevronRight, Briefcase } from 'lucide-react';

const FlowApp = () => {
  const [activeTab, setActiveTab] = useState('home');
  const [showAddMenu, setShowAddMenu] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [showAddTask, setShowAddTask] = useState(false);
  const [showAddTransaction, setShowAddTransaction] = useState(false);
  const [showAddShift, setShowAddShift] = useState(false);
  
  const [tasks, setTasks] = useState([
    { id: 1, title: 'Встреча с клиентом', time: '14:00', done: false, category: 'Работа' },
    { id: 2, title: 'Закончить отчёт', time: '16:30', done: false, category: 'Работа' },
    { id: 3, title: 'Тренировка', time: '19:00', done: false, category: 'Личное' },
    { id: 4, title: 'Купить продукты', time: '20:00', done: true, category: 'Личное' },
  ]);

  const [transactions, setTransactions] = useState([
    { id: 1, title: 'Зарплата', amount: 45000, type: 'income', category: 'Работа', date: 'Сегодня' },
    { id: 2, title: 'Продукты', amount: -2300, type: 'expense', category: 'Продукты', date: 'Вчера' },
    { id: 3, title: 'Фриланс', amount: 15000, type: 'income', category: 'Работа', date: '2 дня назад' },
    { id: 4, title: 'Кафе', amount: -850, type: 'expense', category: 'Развлечения', date: '3 дня назад' },
  ]);

  const [shifts, setShifts] = useState([
    { id: 1, title: 'Работа в офисе', hours: 8, earnings: 3200, date: 'Сегодня' },
    { id: 2, title: 'Фриланс проект', hours: 4, earnings: 2500, date: 'Вчера' },
  ]);

  const stats = {
    monthEarnings: 85400,
    monthHours: 168,
    monthShifts: 22,
    todayTasks: tasks.filter(t => !t.done).length
  };

  const GlassCard = ({ children, className = '' }) => (
    <div className={`backdrop-blur-md bg-white/60 rounded-2xl border border-white/40 ${className}`}>
      {children}
    </div>
  );

  const tasksByCategory = tasks.reduce((acc, task) => {
    if (!acc[task.category]) acc[task.category] = [];
    acc[task.category].push(task);
    return acc;
  }, {});

  const transactionsByCategory = transactions.reduce((acc, tx) => {
    if (!acc[tx.category]) acc[tx.category] = { items: [], total: 0 };
    acc[tx.category].items.push(tx);
    acc[tx.category].total += tx.amount;
    return acc;
  }, {});

  const HomeScreen = () => (
    <div className="space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-3xl font-semibold text-slate-800 mb-1">
            Добро пожаловать
          </h1>
          <p className="text-slate-500">
            {new Date().toLocaleDateString('ru-RU', { day: 'numeric', month: 'long' })}
          </p>
        </div>
        <button 
          onClick={() => setShowSettings(true)}
          className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center hover:bg-slate-200 transition-colors"
        >
          <Settings className="w-5 h-5 text-slate-600" />
        </button>
      </div>

      <GlassCard className="p-6">
        <div className="grid grid-cols-2 gap-6">
          <div>
            <p className="text-slate-500 text-sm mb-1">За месяц</p>
            <p className="text-2xl font-semibold text-slate-800">{stats.monthHours}ч</p>
          </div>
          <div>
            <p className="text-slate-500 text-sm mb-1">Заработано</p>
            <p className="text-2xl font-semibold text-slate-800">₽{stats.monthEarnings.toLocaleString()}</p>
          </div>
        </div>
        <div className="h-px bg-slate-200 my-4" />
        <div className="grid grid-cols-2 gap-6">
          <div>
            <p className="text-slate-500 text-sm mb-1">Задач сегодня</p>
            <p className="text-xl font-semibold text-slate-800">{stats.todayTasks}</p>
          </div>
          <div>
            <p className="text-slate-500 text-sm mb-1">Смен в месяце</p>
            <p className="text-xl font-semibold text-slate-800">{stats.monthShifts}</p>
          </div>
        </div>
      </GlassCard>

      {tasks.filter(t => !t.done).length > 0 && (
        <div>
          <h2 className="text-lg font-semibold text-slate-800 mb-3">Задачи на сегодня</h2>
          <div className="space-y-2">
            {tasks.filter(t => !t.done).slice(0, 3).map(task => (
              <GlassCard key={task.id} className="p-4">
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => {
                      setTasks(tasks.map(t => 
                        t.id === task.id ? { ...t, done: !t.done } : t
                      ));
                    }}
                    className="w-5 h-5 rounded-md border-2 border-slate-400 hover:border-slate-600 transition-colors"
                  />
                  <div className="flex-1">
                    <p className="font-medium text-slate-800">{task.title}</p>
                    <p className="text-sm text-slate-500">{task.time}</p>
                  </div>
                </div>
              </GlassCard>
            ))}
          </div>
        </div>
      )}

      <GlassCard className="p-5">
        <div className="space-y-3">
          <div className="flex justify-between items-center">
            <span className="text-sm font-medium text-slate-700">Цель на месяц: ₽150,000</span>
            <span className="text-sm text-slate-500">57%</span>
          </div>
          <div className="h-2 bg-slate-200 rounded-full overflow-hidden">
            <div 
              className="h-full bg-slate-800 rounded-full transition-all duration-500"
              style={{ width: '57%' }}
            />
          </div>
          <p className="text-sm text-slate-500">
            Осталось: ₽{(150000 - stats.monthEarnings).toLocaleString()}
          </p>
        </div>
      </GlassCard>
    </div>
  );

  const FinanceScreen = () => (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-semibold text-slate-800">Финансы</h1>
        <button 
          onClick={() => setShowSettings(true)}
          className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center hover:bg-slate-200 transition-colors"
        >
          <Settings className="w-5 h-5 text-slate-600" />
        </button>
      </div>

      <GlassCard className="p-6">
        <p className="text-slate-500 text-sm mb-2">Баланс</p>
        <p className="text-4xl font-semibold text-slate-800 mb-6">₽{stats.monthEarnings.toLocaleString()}</p>
        
        <div className="grid grid-cols-2 gap-4">
          <div className="p-4 bg-emerald-50 rounded-xl">
            <div className="flex items-center gap-2 mb-1">
              <TrendingUp className="w-4 h-4 text-emerald-600" />
              <span className="text-sm text-emerald-700">Доходы</span>
            </div>
            <p className="text-xl font-semibold text-emerald-800">+₽92,300</p>
          </div>
          <div className="p-4 bg-red-50 rounded-xl">
            <div className="flex items-center gap-2 mb-1">
              <TrendingUp className="w-4 h-4 text-red-600 rotate-180" />
              <span className="text-sm text-red-700">Расходы</span>
            </div>
            <p className="text-xl font-semibold text-red-800">-₽6,900</p>
          </div>
        </div>
      </GlassCard>

      <div>
        <h2 className="text-lg font-semibold text-slate-800 mb-3">По категориям</h2>
        <div className="space-y-3">
          {Object.entries(transactionsByCategory).map(([category, data]) => (
            <GlassCard key={category} className="p-4">
              <div className="flex items-center justify-between mb-3">
                <h3 className="font-medium text-slate-800">{category}</h3>
                <span className={`text-lg font-semibold ${data.total > 0 ? 'text-emerald-600' : 'text-red-600'}`}>
                  {data.total > 0 ? '+' : ''}₽{Math.abs(data.total).toLocaleString()}
                </span>
              </div>
              <div className="space-y-2">
                {data.items.map(tx => (
                  <div key={tx.id} className="flex items-center justify-between text-sm">
                    <div>
                      <p className="text-slate-700">{tx.title}</p>
                      <p className="text-slate-400 text-xs">{tx.date}</p>
                    </div>
                    <span className={`font-medium ${tx.type === 'income' ? 'text-emerald-600' : 'text-red-600'}`}>
                      {tx.amount > 0 ? '+' : ''}₽{Math.abs(tx.amount).toLocaleString()}
                    </span>
                  </div>
                ))}
              </div>
            </GlassCard>
          ))}
        </div>
      </div>
    </div>
  );

  const TasksScreen = () => (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-semibold text-slate-800">Задачи</h1>
        <button 
          onClick={() => setShowSettings(true)}
          className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center hover:bg-slate-200 transition-colors"
        >
          <Settings className="w-5 h-5 text-slate-600" />
        </button>
      </div>

      <div className="flex gap-2 overflow-x-auto pb-2">
        {['Все', 'Сегодня', 'Выполнено'].map((filter, i) => (
          <button
            key={i}
            className={`px-4 py-2 rounded-lg whitespace-nowrap transition-colors ${
              i === 0
                ? 'bg-slate-800 text-white'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            {filter}
          </button>
        ))}
      </div>

      <div className="space-y-4">
        {Object.entries(tasksByCategory).map(([category, categoryTasks]) => (
          <div key={category}>
            <h3 className="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-2">
              {category}
            </h3>
            <div className="space-y-2">
              {categoryTasks.map(task => (
                <GlassCard key={task.id} className="p-4">
                  <div className="flex items-center gap-3">
                    <button
                      onClick={() => {
                        setTasks(tasks.map(t => 
                          t.id === task.id ? { ...t, done: !t.done } : t
                        ));
                      }}
                      className={`w-5 h-5 rounded-md border-2 transition-all ${
                        task.done 
                          ? 'bg-slate-800 border-slate-800' 
                          : 'border-slate-400 hover:border-slate-600'
                      }`}
                    >
                      {task.done && <CheckCircle className="w-4 h-4 text-white" />}
                    </button>
                    <div className="flex-1">
                      <p className={`font-medium ${task.done ? 'line-through text-slate-400' : 'text-slate-800'}`}>
                        {task.title}
                      </p>
                      <div className="flex items-center gap-1 mt-1">
                        <Clock className="w-3 h-3 text-slate-400" />
                        <span className="text-sm text-slate-500">{task.time}</span>
                      </div>
                    </div>
                  </div>
                </GlassCard>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  const ScheduleScreen = () => (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-semibold text-slate-800">График</h1>
        <button 
          onClick={() => setShowSettings(true)}
          className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center hover:bg-slate-200 transition-colors"
        >
          <Settings className="w-5 h-5 text-slate-600" />
        </button>
      </div>

      <GlassCard className="p-5">
        <div className="flex justify-between items-center mb-4">
          <h3 className="font-semibold text-slate-800">Ноябрь 2024</h3>
          <button className="text-sm text-slate-600 hover:text-slate-800 transition-colors">
            Сегодня
          </button>
        </div>
        
        <div className="grid grid-cols-7 gap-1">
          {['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'].map((day, i) => (
            <div key={i} className="text-center text-slate-500 text-xs py-2">
              {day}
            </div>
          ))}
          {Array.from({ length: 35 }, (_, i) => {
            const dayNum = i - 2;
            const isToday = dayNum === 29;
            const hasShift = [1, 3, 5, 8, 10, 12, 15, 17, 19, 22, 24, 26, 29].includes(dayNum);
            
            return (
              <button
                key={i}
                className={`aspect-square rounded-lg flex items-center justify-center text-sm font-medium transition-colors ${
                  dayNum < 1 || dayNum > 30
                    ? 'text-slate-300'
                    : isToday
                    ? 'bg-slate-800 text-white'
                    : hasShift
                    ? 'bg-slate-100 text-slate-800 hover:bg-slate-200'
                    : 'text-slate-600 hover:bg-slate-50'
                }`}
              >
                {dayNum > 0 && dayNum <= 30 && dayNum}
              </button>
            );
          })}
        </div>
      </GlassCard>

      <div>
        <h2 className="text-lg font-semibold text-slate-800 mb-3">Смены сегодня</h2>
        <div className="space-y-2">
          {shifts.map(shift => (
            <GlassCard key={shift.id} className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-slate-100 flex items-center justify-center">
                    <Briefcase className="w-5 h-5 text-slate-600" />
                  </div>
                  <div>
                    <p className="font-medium text-slate-800">{shift.title}</p>
                    <p className="text-sm text-slate-500">{shift.hours}ч</p>
                  </div>
                </div>
                <p className="text-lg font-semibold text-slate-800">₽{shift.earnings.toLocaleString()}</p>
              </div>
            </GlassCard>
          ))}
        </div>
      </div>
    </div>
  );

  const screens = {
    home: <HomeScreen />,
    finance: <FinanceScreen />,
    tasks: <TasksScreen />,
    schedule: <ScheduleScreen />,
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 p-4 pb-24">
      <div className="max-w-md mx-auto">
        <div className="mb-6">
          {screens[activeTab]}
        </div>
      </div>

      {/* Нижняя навигация */}
      <div className="fixed bottom-4 left-4 right-4 max-w-md mx-auto">
        <GlassCard className="px-2 py-3">
          <div className="flex justify-around items-center">
            {[
              { id: 'home', icon: Home, label: 'Главная' },
              { id: 'finance', icon: DollarSign, label: 'Финансы' },
            ].map((tab) => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;
              
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex flex-col items-center gap-1 px-4 py-2 rounded-xl transition-colors ${
                    isActive ? 'bg-slate-100' : 'hover:bg-slate-50'
                  }`}
                >
                  <Icon className={`w-5 h-5 ${isActive ? 'text-slate-800' : 'text-slate-400'}`} />
                  <span className={`text-xs font-medium ${isActive ? 'text-slate-800' : 'text-slate-400'}`}>
                    {tab.label}
                  </span>
                </button>
              );
            })}
            
            {/* Центральная кнопка + */}
            <button
              onClick={() => setShowAddMenu(true)}
              className="w-14 h-14 -mt-8 rounded-2xl bg-slate-800 flex items-center justify-center shadow-lg hover:bg-slate-900 transition-colors"
            >
              <Plus className="w-7 h-7 text-white" />
            </button>
            
            {[
              { id: 'tasks', icon: CheckCircle, label: 'Задачи' },
              { id: 'schedule', icon: Calendar, label: 'График' },
            ].map((tab) => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;
              
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex flex-col items-center gap-1 px-4 py-2 rounded-xl transition-colors ${
                    isActive ? 'bg-slate-100' : 'hover:bg-slate-50'
                  }`}
                >
                  <Icon className={`w-5 h-5 ${isActive ? 'text-slate-800' : 'text-slate-400'}`} />
                  <span className={`text-xs font-medium ${isActive ? 'text-slate-800' : 'text-slate-400'}`}>
                    {tab.label}
                  </span>
                </button>
              );
            })}
          </div>
        </GlassCard>
      </div>

      {/* Меню добавления */}
      {showAddMenu && (
        <div 
          className="fixed inset-0 bg-black/20 backdrop-blur-sm z-50 flex items-end"
          onClick={() => setShowAddMenu(false)}
        >
          <div 
            className="w-full max-w-md mx-auto mb-4 px-4"
            onClick={(e) => e.stopPropagation()}
          >
            <GlassCard className="p-6">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-xl font-semibold text-slate-800">Добавить</h2>
                <button 
                  onClick={() => setShowAddMenu(false)}
                  className="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center hover:bg-slate-200 transition-colors"
                >
                  <X className="w-4 h-4 text-slate-600" />
                </button>
              </div>
              
              <div className="space-y-2">
                {[
                  { title: 'Задачу', subtitle: 'Создать новую задачу', icon: CheckCircle, action: () => setShowAddTask(true) },
                  { title: 'Операцию', subtitle: 'Доход или расход', icon: DollarSign, action: () => setShowAddTransaction(true) },
                  { title: 'Смену', subtitle: 'Добавить в график', icon: Calendar, action: () => setShowAddShift(true) },
                ].map((item, i) => {
                  const Icon = item.icon;
                  return (
                    <button
                      key={i}
                      onClick={() => {
                        setShowAddMenu(false);
                        item.action();
                      }}
                      className="w-full p-4 rounded-xl bg-slate-50 hover:bg-slate-100 transition-colors text-left"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-slate-800 flex items-center justify-center">
                          <Icon className="w-5 h-5 text-white" />
                        </div>
                        <div className="flex-1">
                          <p className="font-medium text-slate-800">{item.title}</p>
                          <p className="text-sm text-slate-500">{item.subtitle}</p>
                        </div>
                        <ChevronRight className="w-5 h-5 text-slate-400" />
                      </div>
                    </button>
                  );
                })}
              </div>
            </GlassCard>
          </div>
        </div>
      )}

      {/* Модальное окно настроек */}
      {showSettings && (
        <div 
          className="fixed inset-0 bg-black/20 backdrop-blur-sm z-50 flex items-center justify-center p-4"
          onClick={() => setShowSettings(false)}
        >
          <div 
            className="w-full max-w-md"
            onClick={(e) => e.stopPropagation()}
          >
            <GlassCard className="p-6">
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-2xl font-semibold text-slate-800">Настройки</h2>
                <button 
                  onClick={() => setShowSettings(false)}
                  className="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center hover:bg-slate-200 transition-colors"
                >
                  <X className="w-4 h-4 text-slate-600" />
                </button>
              </div>

              {/* Профиль */}
              <div className="mb-6 p-4 rounded-xl bg-slate-50">
                <div className="flex items-center gap-3">
                  <div className="w-14 h-14 rounded-xl bg-slate-800 flex items-center justify-center text-white text-xl font-semibold">
                    А
                  </div>
                  <div>
                    <p className="font-medium text-slate-800">Александр</p>
                    <p className="text-sm text-slate-500">alex@example.com</p>
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <div>
                  <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">
                    Аккаунт
                  </p>
                  <div className="space-y-2">
                    {[
                      { label: 'Имя', value: 'Александр' },
                      { label: 'Email', value: 'alex@example.com' },
                    ].map((item, i) => (
                      <button
                        key={i}
                        className="w-full p-3 rounded-xl bg-slate-50 hover:bg-slate-100 transition-colors text-left flex items-center justify-between"
                      >
                        <div>
                          <p className="text-xs text-slate-500">{item.label}</p>
                          <p className="font-medium text-slate-800">{item.value}</p>
                        </div>
                        <ChevronRight className="w-4 h-4 text-slate-400" />
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">
                    Настройки
                  </p>
                  <div className="space-y-2">
                    <button className="w-full p-3 rounded-xl bg-slate-50 hover:bg-slate-100 transition-colors text-left flex items-center justify-between">
                      <div>
                        <p className="text-xs text-slate-500">Валюта</p>
                        <p className="font-medium text-slate-800">₽ Рубль</p>
                      </div>
                      <ChevronRight className="w-4 h-4 text-slate-400" />
                    </button>
                    <button className="w-full p-3 rounded-xl bg-slate-50 hover:bg-slate-100 transition-colors text-left flex items-center justify-between">
                      <div>
                        <p className="text-xs text-slate-500">Тема</p>
                        <p className="font-medium text-slate-800">Светлая</p>
                      </div>
                      <ChevronRight className="w-4 h-4 text-slate-400" />
                    </button>
                  </div>
                </div>
              </div>
            </GlassCard>
          </div>
        </div>
      )}
    </div>
  );
};

export default FlowApp;