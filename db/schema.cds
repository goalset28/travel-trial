using { cuid, managed, Currency, sap.common.CodeList } from '@sap/cds/common';

namespace sap.travel;

// ============ 类型 ============
type AuditLevel : String(1) enum { Request = 'R'; Expense = 'E'; };
type UserType   : String(1) enum { Internal = 'I'; External = 'E'; System = 'S'; };

// ============ 地理主数据 ============
entity Countries : CodeList {
  key code      : String(6);                    // CN、US、US-HI
  stateRequired : Boolean default false;        // CA CH US 为 true
  parent        : Association to Countries;     // US-HI 的上级是 US
  displayName   : String(120) = '(' || code || ') ' || name;   // (CN) CHINA
}

entity Cities : cuid {
  name        : String(100);                    // Shenzhen
  province    : String(100);                    // Guangdong
  country     : Association to Countries;
  displayName : String(210) = name || ', ' || province;        // Shenzhen, Guangdong
}

entity Airports : CodeList {
  key code : String(3);                         // SHA SZX
  city     : Association to Cities;
}

// ============ 组织主数据 ============
entity Departments : cuid {
  code       : String(10);
  name       : String(100);
  deptType   : Association to DepartmentTypes;  // BUSINESS FINANCE AUDIT AGENCY
  parent     : Association to Departments;      // 上级部门
  head       : Association to Employees;        // 部门负责人
  costCenter : String(20);
}

entity Employees : cuid {
  employeeNo      : String(20);
  name            : String(100);
  email           : String(255);
  userId          : String(100);                // 登录名，第五步授权时对应 $user.id
  userType        : UserType default 'I';       // 内部 / 外部（旅行社）/ 系统（Concur System）
  department      : Association to Departments;
  manager         : Association to Employees;   // 直属经理
  defaultCurrency : Currency;                   // 新建申请时预填，如 CNY
  isActive        : Boolean default true;
  roles           : Composition of many EmployeeRoles on roles.employee = $self;
}

entity EmployeeRoles : cuid {
  employee : Association to Employees;
  role     : Association to BusinessRoles;
}

// ============ 差旅申请 ============
entity TravelRequests : cuid, managed {
  requestId     : String(10);
  purpose       : String(200);                  // 同时也是页面标题
  employee      : Association to Employees;     // 申请人
  department    : Association to Departments;   // 提交时的部门快照
  startDate     : Date;
  endDate       : Date;
  country       : Association to Countries;
  state         : String(50);                   // stateRequired 为 true 的国家必填
  city          : Association to Cities;        // Main Destination City
  tripCategory  : Association to TripCategories;
  status        : Association to TravelStatus default 'NS';
  estimatedCost : Decimal(15,2);                // Estimated Trip Cost，用户手填
  currency      : Currency;
  comment       : String(500);

  expenses      : Composition of many ExpectedExpenses on expenses.travel      = $self;
  approvalSteps : Composition of many ApprovalSteps    on approvalSteps.travel = $self;
  auditTrail    : Composition of many AuditTrail       on auditTrail.travel    = $self;
}

// ============ 行项目（酒店 / 机票共用） ============
entity ExpectedExpenses : cuid {
  travel          : Association to TravelRequests;
  expenseType     : Association to ExpenseTypes;
  expenseDate     : Date;                       // 列表里的 Date 列
  amount          : Decimal(15,2);              // 可编辑
  requestedAmount : Decimal(15,2);              // 可编辑
  currency        : Currency;

  // 酒店
  city            : Association to Cities;
  checkIn         : Date;
  checkOut        : Date;
  comment         : String(2000);

  // 机票
  tripType        : Association to TripTypes;
  fromAirport     : Association to Airports;
  toAirport       : Association to Airports;
  outboundDate    : Date;
  outboundTime    : Time;
  outboundComment : String(2000);
  returnDate      : Date;
  returnTime      : Time;
  returnComment   : String(2000);
}

// ============ 审批流 ============
entity ApprovalSteps : cuid {
  travel       : Association to TravelRequests;
  stepNo       : Integer;
  stepName     : String(50);                    // Line Manager Approval / L1 Approval
  approver     : Association to Employees;      // Meng Xu / Concur System
  approverRole : Association to BusinessRoles;
  actionTime   : Timestamp;
  completed    : Boolean default false;
}

// ============ 审计日志（申请级和行项目级共用） ============
entity AuditTrail : cuid {
  travel      : Association to TravelRequests;
  expense     : Association to ExpectedExpenses;   // 申请级为空
  auditLevel  : AuditLevel;
  eventTime   : Timestamp;
  updatedBy   : Association to Employees;
  action      : Association to AuditActions;
  description : String(2000);                      // Exception / 通知的文字
  fromStatus  : Association to TravelStatus;       // 以下三项仅状态变更使用
  toStatus    : Association to TravelStatus;
  stepName    : String(50);
  comment     : String(500);
}

// ============ 代码表 ============
entity TravelStatus    : CodeList { key code : String(2);  }  // NS SU LM L1 AP AA RJ
entity TripCategories  : CodeList { key code : String(10); }  // CUSTOMER EDUCATION MA_INTEG SAP_INT
entity ExpenseTypes    : CodeList { key code : String(10); }  // HOTEL AIR
entity TripTypes       : CodeList { key code : String(2);  }  // OW RT
entity AuditActions    : CodeList { key code : String(20); }  // STATUS_CHANGE EXCEPTION AGENCY_NOTIFY
entity BusinessRoles   : CodeList { key code : String(20); }  // EMPLOYEE LINE_MANAGER FINANCE AUDITOR AGENCY
entity DepartmentTypes : CodeList { key code : String(10); }  // BUSINESS FINANCE AUDIT AGENCY