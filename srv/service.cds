using { sap.travel as db } from '../db/schema';

service TravelService {

  // ============ 业务实体 ============
  @odata.draft.enabled
  entity TravelRequests as projection on db.TravelRequests {
    *,
    // 审计日志按层级拆成两个视图
    requestAudit : Association to many AuditTrail
                     on requestAudit.travel = $self and requestAudit.auditLevel = 'R',
    expenseAudit : Association to many AuditTrail
                     on expenseAudit.travel = $self and expenseAudit.auditLevel = 'E',
    // 头部 Alerts: N，第四步由 handler 计算
    virtual null as alertCount : Integer
  } actions {
    action submit();
    action approve(comment : String(500));
    action reject (comment : String(500));
  };

  entity ExpectedExpenses as projection on db.ExpectedExpenses {
    *,
    virtual null as details  : String,    // Details 列的拼接文本
    virtual null as hasAlert : Boolean    // 行上的 ⚠ 图标
  };

  entity ApprovalSteps as projection on db.ApprovalSteps;
  entity AuditTrail    as projection on db.AuditTrail;

  // ============ 只读主数据（用于 Value Help） ============
  @readonly entity Countries      as projection on db.Countries;
  @readonly entity Cities         as projection on db.Cities;
  @readonly entity Airports       as projection on db.Airports;
  @readonly entity TripCategories as projection on db.TripCategories;
  @readonly entity ExpenseTypes   as projection on db.ExpenseTypes;
  @readonly entity TripTypes      as projection on db.TripTypes;
  @readonly entity TravelStatus   as projection on db.TravelStatus;
  @readonly entity Departments    as projection on db.Departments;

  // 员工只暴露必要字段，不暴露邮箱、登录名
  @readonly entity Employees as projection on db.Employees {
    ID, employeeNo, name, department, manager, defaultCurrency
  };
}