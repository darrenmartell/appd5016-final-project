import { useQuery } from '@tanstack/react-query'
import { Outlet } from 'react-router-dom';
import config from '../config';

const Users = () => {
  
  const fetchUsers = async () => {
    const response = await fetch(`${config.API_URL}/users`)
    const data = await response.json()
    return data
  }

  const {
    data: users = [],
    isLoading,
    error
   } = useQuery({
    queryKey: ["userCache"],
    queryFn: fetchUsers
  })


  return (
    <div className="max-w-4xl mx-auto my-8 p-6 bg-zinc-900 rounded-lg border border-zinc-800 shadow-lg">
      <h1 className="text-2xl font-bold text-white mb-2">User Management</h1>
      <Outlet context={{ users, isLoading, error }} />
    </div>
  );
};
export default Users;
