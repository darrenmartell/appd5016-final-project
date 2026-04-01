import { Navigate, Outlet, useOutletContext } from 'react-router-dom';

const Series = () => {

  const context = useOutletContext(); // Get any context passed from parent route

  return (
    <div className="max-w-4xl mx-auto my-8 p-6 bg-zinc-900 rounded-lg border border-zinc-800 shadow-lg">
      <h1 className="text-2xl font-bold text-white mb-2">Series Management</h1>
      <Outlet context={context} />
    </div>
  );
};

export default Series;
