import { Routes, Route, Navigate } from 'react-router-dom';
import App from '../App';
import Users from '../pages/Users';
import Dashboard from '../pages/Dashboard';
import Login from '../pages/Login';

import UserTable from '../components/users/UserTable';
import UserDetails from '../components/users/UserDetails';
import Register from '../pages/Register';
import ProtectedRoute from './ProtectedRoute';
import DeleteUser from '../components/users/DeleteUser';
import Series from '../pages/Series';
import SeriesTable from '../components/series/SeriesTable';
import SeriesDetails from '../components/series/SeriesDetails';
import DeleteSeries from '../components/series/DeleteSeries';
import SeriesForm from '../components/series/SeriesForm';
import ChangePassword from '../pages/ChangePassword';

const AppRoutes = () => (
  <Routes>
    <Route path="/" element={<Navigate to="/admin/home" replace />} />
    <Route path="/admin" element={<Navigate to="/admin/home" replace />} />
    <Route path="/admin" element={<App />} >
      <Route path="home" element={<Dashboard />} />
      <Route path="users" element={<Users />}>
        <Route index element={<UserTable />} />
        <Route path=":id/details" element={<UserDetails />} />
        <Route element={<ProtectedRoute />}>
          <Route path=":id/delete" element={<DeleteUser />} />
        </Route>
      </Route>
      <Route path="series" element={<Series />}>
        <Route index element={<SeriesTable />} />
        <Route path=":id/details" element={<SeriesDetails />} />
        <Route element={<ProtectedRoute />}>
          <Route path="add" element={<SeriesForm editable={false} />} />
          <Route path=":id/update" element={<SeriesForm editable={true} />} />
          <Route path=":id/delete" element={<DeleteSeries />} />
        </Route>
      </Route>
    </Route>
    <Route path="/login" element={<App />} >
      <Route index element={<Login />} />
    </Route>
    <Route path="/register" element={<App />} >
      {/* "index" is the default when path=register only */}
      <Route index element={<Register />} />
    </Route>
    <Route path="/changepassword" element={<App />} >
      {/* "index" is the default when path=register only */}
      <Route index element={<ChangePassword />} />
    </Route>
  </Routes>
);

export default AppRoutes;